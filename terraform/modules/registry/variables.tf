variable "repository_name" {
  description = "Name of the container repository, for example sokoprice/app."
  type        = string
}

variable "force_delete" {
  description = "Allow terraform destroy to delete the repository even if it still contains images (convenient for a lab, off for prod)."
  type        = bool
  default     = true
}

variable "keep_last_images" {
  description = "Number of most recent images to keep. Older images are deleted automatically."
  type        = number
  default     = 20
}
