# These two secrets are written (and kept in sync) by Terraform.
# Any manual edits to AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY in Infisical
# will be overwritten on the next `terraform apply`.
#
# NOTE: aws_iam_access_key.backend.secret is stored in Terraform state.
# Protect your state file (or migrate to remote state) accordingly.

import {
  to = infisical_secret.aws_access_key_id
  id = "${var.infisical_project_id}:${var.infisical_env_slug}:/:AWS_ACCESS_KEY_ID"
}

resource "infisical_secret" "aws_access_key_id" {
  name         = "AWS_ACCESS_KEY_ID"
  value        = aws_iam_access_key.backend.id
  env_slug     = var.infisical_env_slug
  workspace_id = var.infisical_project_id
  folder_path  = "/"
}

import {
  to = infisical_secret.aws_secret_access_key
  id = "${var.infisical_project_id}:${var.infisical_env_slug}:/:AWS_SECRET_ACCESS_KEY"
}

resource "infisical_secret" "aws_secret_access_key" {
  name         = "AWS_SECRET_ACCESS_KEY"
  value        = aws_iam_access_key.backend.secret
  env_slug     = var.infisical_env_slug
  workspace_id = var.infisical_project_id
  folder_path  = "/"
}
