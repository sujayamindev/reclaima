output "instance_public_ip" {
  description = "Ephemeral public IP of the backend VM. Stable across reboots and stop/starts; only released if the instance is terminated."
  value       = data.oci_core_vnic.backend_primary.public_ip_address
}

output "instance_id" {
  description = "OCI instance OCID. Useful for OCI Console lookups and troubleshooting."
  value       = oci_core_instance.backend.id
}

output "data_volume_id" {
  description = "OCID of the persistent data block volume (postgres, monitoring data)."
  value       = oci_core_volume.data.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket managed by Terraform."
  value       = aws_s3_bucket.receipts.arn
}

output "iam_user_arn" {
  description = "ARN of the backend IAM user managed by Terraform."
  value       = aws_iam_user.backend.arn
}

output "iam_access_key_id" {
  description = "AWS access key ID (also written to Infisical as AWS_ACCESS_KEY_ID)."
  value       = aws_iam_access_key.backend.id
  sensitive   = true
}

output "oci_namespace" {
  description = "OCI Object Storage namespace. Needed for backend.tf.example when migrating to remote state."
  value       = data.oci_objectstorage_namespace.current.namespace
}

output "terraform_state_bucket" {
  description = "OCI Object Storage bucket name for Terraform remote state. See backend.tf.example."
  value       = oci_objectstorage_bucket.terraform_state.name
}
