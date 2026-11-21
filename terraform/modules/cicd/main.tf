# -----------------------------------------------------------------------------
# CI/CD module: lets GitHub Actions deploy without any stored AWS keys.
#
# GitHub Actions proves who it is with a short-lived OpenID Connect (OIDC) token.
# AWS exchanges that token for temporary credentials, but only for a workflow
# that runs in THIS repository on THIS branch. There is no access key to leak,
# rotate or commit.
#
# The role can do exactly four things and nothing else:
#   1. push images to this one container repository,
#   2. read this one database secret (and decrypt it),
#   3. open and close SSH access on the bastion security group for the
#      runner's own address during a deployment,
#   4. ask ECR for a login token.
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  github_owner = split("/", var.github_repository)[0]
  github_name  = split("/", var.github_repository)[1]

  # GitHub can send the repository either by name or, for repositories that use
  # the newer "immutable subject", as owner@id/repo@id. The * stands for the
  # numeric id only: the owner and the repository name are always fixed.
  trusted_subjects = [
    "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}",
    "repo:${var.github_repository}:environment:production",
    "repo:${local.github_owner}@*/${local.github_name}@*:ref:refs/heads/${var.github_branch}",
    "repo:${local.github_owner}@*/${local.github_name}@*:environment:production",
  ]

  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
  bastion_sg_arn    = "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/${var.bastion_security_group_id}"
}

# An AWS account can hold only one OIDC provider per issuer. If your account
# already has the GitHub one, set create_oidc_provider = false.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS no longer uses this value for GitHub's certificate, but older provider
  # versions require the argument.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

# ---------------------------------- Trust ------------------------------------

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only workflows of this repository: runs on the deployment branch, and the
    # deploy job, which uses the "production" environment.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.trusted_subjects
    }
  }
}

resource "aws_iam_role" "deploy" {
  name                 = "${var.name_prefix}-github-deploy"
  description          = "Assumed by the GitHub Actions deployment workflow of ${var.github_repository}"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600
}

# -------------------------------- Permissions --------------------------------

data "aws_iam_policy_document" "deploy" {
  #checkov:skip=CKV_AWS_355:ecr:GetAuthorizationToken does not support resource-level permissions, so "*" is the only value AWS accepts. Everything else in this policy is limited to one resource.
  statement {
    sid       = "EcrLogin"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushImagesToThisRepositoryOnly"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    resources = [var.ecr_repository_arn]
  }

  statement {
    sid       = "ReadTheDatabaseSecretOnly"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }

  statement {
    sid       = "DecryptTheDatabaseSecretOnly"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [var.db_secret_kms_key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.aws_region}.amazonaws.com"]
    }
  }

  statement {
    sid       = "OpenAndCloseSshOnTheBastionOnly"
    effect    = "Allow"
    actions   = ["ec2:AuthorizeSecurityGroupIngress", "ec2:RevokeSecurityGroupIngress"]
    resources = [local.bastion_sg_arn]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name_prefix = "deploy-"
  role        = aws_iam_role.deploy.id
  policy      = data.aws_iam_policy_document.deploy.json
}
