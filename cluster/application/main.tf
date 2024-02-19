locals {
  # local.environments is a list of environment names indexed by this cluster
  environments = try(var.application.environments[var.cluster_name], [])

  # Shared prefix for any directory-like structure (e.g., CloudWatch or
  # Parameter Store). Use this to avoid introducing potential copy/paste errors.
  directory_prefix = "/${var.cluster_name}/applications/${var.application.name}"
}
