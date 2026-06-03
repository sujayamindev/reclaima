# OCI Object Storage bucket for Terraform remote state.
#
# Bootstrap sequence (one-time):
#   1. Run `terraform apply` with the default local backend to create all
#      resources including this bucket.
#   2. Copy backend.tf.example → backend.tf.
#   3. Fill in all four credential placeholders (tenancy_ocid, user_ocid,
#      fingerprint, private_key_path) — same values as in terraform.tfvars.
#      Get the namespace with: terraform output oci_namespace
#   4. Run `terraform init -migrate-state` to upload local state to OCI.

data "oci_objectstorage_namespace" "current" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "terraform_state" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.current.namespace
  name           = "reclaima-terraform-state"
  access_type    = "NoPublicAccess"
  versioning     = "Enabled"
}
