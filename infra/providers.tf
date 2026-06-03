provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.oci_user_ocid
  fingerprint      = var.oci_api_fingerprint
  private_key_path = var.oci_private_key_path
  region           = var.oci_region
}

provider "aws" {
  region = var.aws_region
}

provider "infisical" {
  host = "https://app.infisical.com"
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}
