# -----------------------------------------------------------------------------
# Monitoring module: logs, alarms, notifications and a dashboard.
#
#   * Application log group: the Docker log driver on the server ships container
#     logs here (encrypted, kept for a year).
#   * Alarms: unhealthy servers, server errors, high CPU, failed status checks,
#     low database storage. Each one notifies an SNS topic.
#   * Dashboard: one page showing traffic, errors, health, CPU and database
#     state. This is the runtime evidence for the demo.
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# ----------------------------------- Key -------------------------------------

data "aws_iam_policy_document" "key" {
  #checkov:skip=CKV_AWS_109:Standard KMS key policy. The account root statement is required so that IAM can administer the key; without it the key becomes unmanageable.
  #checkov:skip=CKV_AWS_111:Same statement as CKV_AWS_109. Use of the key by the logging and alarm services is limited to the service principals below.
  #checkov:skip=CKV_AWS_356:In a key policy the resource "*" always means "this key", so it cannot be narrowed further.
  statement {
    sid       = "EnableAccountAdministration"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowCloudWatchLogsToUseTheKey"
    effect    = "Allow"
    actions   = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:*"]
    }
  }

  statement {
    sid       = "AllowCloudWatchAlarmsToPublishToTheTopic"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "Encrypts the ${var.name_prefix} application logs and alert notifications"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.key.json
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}-monitoring"
  target_key_id = aws_kms_key.this.key_id
}

# ---------------------------------- Logs -------------------------------------

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.project_name}/${var.environment}/app"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.this.arn
}

# ------------------------------- Notifications -------------------------------

resource "aws_sns_topic" "alerts" {
  name              = "${var.name_prefix}-alerts"
  kms_master_key_id = aws_kms_key.this.id
}

# The subscriber must click the confirmation link in the e-mail AWS sends.
resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email == "" ? 0 : 1

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------------------------------- Alarms -----------------------------------

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.name_prefix}-unhealthy-servers"
  alarm_description   = "The load balancer reports an unhealthy application server: /health is failing."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "server_errors" {
  alarm_name          = "${var.name_prefix}-http-5xx"
  alarm_description   = "The application returned more than 10 server errors (HTTP 5xx) in 5 minutes."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "app_cpu" {
  alarm_name          = "${var.name_prefix}-app-cpu-high"
  alarm_description   = "The application server CPU has been above 80 percent for 10 minutes."
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.app_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "app_status_check" {
  alarm_name          = "${var.name_prefix}-app-status-check-failed"
  alarm_description   = "The application server failed an EC2 status check (hardware or operating system problem)."
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.app_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  alarm_name          = "${var.name_prefix}-db-cpu-high"
  alarm_description   = "The database CPU has been above 80 percent for 10 minutes."
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "db_storage" {
  alarm_name          = "${var.name_prefix}-db-storage-low"
  alarm_description   = "The database has less than 2 GiB of free storage."
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2147483648
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }
}

# -------------------------------- Dashboard ----------------------------------

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name_prefix}-overview"

  dashboard_body = <<-EOT
    {
      "widgets": [
        {
          "type": "metric", "x": 0, "y": 0, "width": 12, "height": 6,
          "properties": {
            "title": "Requests and server errors (load balancer)",
            "region": "${var.aws_region}", "view": "timeSeries", "stat": "Sum", "period": 60,
            "metrics": [
              ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${var.alb_arn_suffix}"],
              ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${var.alb_arn_suffix}"]
            ]
          }
        },
        {
          "type": "metric", "x": 12, "y": 0, "width": 12, "height": 6,
          "properties": {
            "title": "Healthy and unhealthy servers",
            "region": "${var.aws_region}", "view": "timeSeries", "stat": "Maximum", "period": 60,
            "metrics": [
              ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", "${var.alb_arn_suffix}", "TargetGroup", "${var.target_group_arn_suffix}"],
              ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", "${var.alb_arn_suffix}", "TargetGroup", "${var.target_group_arn_suffix}"]
            ]
          }
        },
        {
          "type": "metric", "x": 0, "y": 6, "width": 12, "height": 6,
          "properties": {
            "title": "Response time (seconds, average)",
            "region": "${var.aws_region}", "view": "timeSeries", "stat": "Average", "period": 60,
            "metrics": [
              ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${var.alb_arn_suffix}"]
            ]
          }
        },
        {
          "type": "metric", "x": 12, "y": 6, "width": 12, "height": 6,
          "properties": {
            "title": "Application server CPU (percent)",
            "region": "${var.aws_region}", "view": "timeSeries", "stat": "Average", "period": 300,
            "metrics": [
              ["AWS/EC2", "CPUUtilization", "InstanceId", "${var.app_instance_id}"]
            ]
          }
        },
        {
          "type": "metric", "x": 0, "y": 12, "width": 12, "height": 6,
          "properties": {
            "title": "Database CPU (percent) and connections",
            "region": "${var.aws_region}", "view": "timeSeries", "stat": "Average", "period": 300,
            "metrics": [
              ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.db_identifier}"],
              ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${var.db_identifier}"]
            ]
          }
        },
        {
          "type": "metric", "x": 12, "y": 12, "width": 12, "height": 6,
          "properties": {
            "title": "Database free storage (bytes)",
            "region": "${var.aws_region}", "view": "timeSeries", "stat": "Minimum", "period": 300,
            "metrics": [
              ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${var.db_identifier}"]
            ]
          }
        },
        {
          "type": "log", "x": 0, "y": 18, "width": 24, "height": 6,
          "properties": {
            "title": "Latest application log lines",
            "region": "${var.aws_region}", "view": "table",
            "query": "SOURCE '${aws_cloudwatch_log_group.app.name}' | fields @timestamp, @message | sort @timestamp desc | limit 20"
          }
        }
      ]
    }
  EOT
}
