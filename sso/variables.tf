variable "okta_group_name" {
  description = "Name of the group (in Okta) of users who can assume this role"
  type        = string
}

variable "inline_policy" {
  description = "Inline policy to add to this permission set"
  type        = string
  default     = ""
}

variable "aws_managed_policies" {
  description = "Additional AWS-managed policies to add to this permission set"
  type        = list(string)
  default     = []
}

variable "custom_managed_policies" {
  description = "Names (not ARNs) of custom policies to add to this permission set"
  type        = list(string)
  default     = []
}

variable "env_bucket_arns" {
  description = "ARN(s) of the S3 bucket(s) in which environment files are stored"
  type        = list(string)
  default     = []
}

variable "backup_bucket_arns" {
  description = "ARN(s) of the S3 bucket(s) in which backups are stored"
  type        = list(string)
  default     = []
}

variable "ecs_cluster_arns" {
  description = "ARN(s) of the ECS clusters"
  type        = list(string)
  default     = []
}

variable "task_role_arns" {
  description = "ARN(s) of task roles for this cluster"
  type        = list(string)
  default     = []
}

variable "permission_set_name" {
  description = "Name of the permission set (visible in the AWS SSO console)"
  type        = string
}

variable "permission_set_description" {
  description = "Description for the permission set"
  type        = string
  default     = "Grants access to ECS resources"
}

variable "session_duration" {
  description = "Maximum length of a session"
  type        = string
  default     = "PT8H"
}

variable "target_account" {
  description = "Account to which this permission set applies"
  type        = string
}
