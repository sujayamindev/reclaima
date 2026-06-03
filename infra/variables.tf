# ─── OCI Authentication ───────────────────────────────────────────────────────

variable "tenancy_ocid" {
  description = "OCI tenancy OCID. Found in: OCI Console → Profile (top-right) → Tenancy."
  type        = string
  sensitive   = true
}

variable "oci_user_ocid" {
  description = "OCI user OCID for API access. Found in: OCI Console → Profile → User Settings."
  type        = string
  sensitive   = true
}

variable "oci_api_fingerprint" {
  description = "Fingerprint of the OCI API signing key. Found in: OCI Console → User Settings → API Keys."
  type        = string
}

variable "oci_private_key_path" {
  description = "Local path to the OCI API private key (.pem file) used for provider authentication."
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "oci_region" {
  description = "OCI region identifier."
  type        = string
  default     = "ap-singapore-1"
}

# ─── OCI Compartment ──────────────────────────────────────────────────────────

variable "compartment_ocid" {
  description = "OCID of the OCI compartment to deploy all resources into. Use the root compartment OCID (same as tenancy_ocid) or a dedicated child compartment."
  type        = string
}

# ─── Compute ──────────────────────────────────────────────────────────────────

variable "instance_ocpus" {
  description = "OCPUs for VM.Standard.A1.Flex. Always Free tier maximum is 4."
  type        = number
  default     = 4
}

variable "instance_memory_gb" {
  description = "RAM in GB for VM.Standard.A1.Flex. Always Free tier maximum is 24 GB."
  type        = number
  default     = 24
}

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB. OCI minimum is 50 GB."
  type        = number
  default     = 50
}

variable "data_volume_size_gb" {
  description = "Separate block volume for persistent container data: postgres_data, Prometheus, Loki, Grafana. Mounted at /mnt/data."
  type        = number
  default     = 100
}

# ─── Existing OCI Resource OCIDs (for import) ────────────────────────────────
# All of these already exist. Terraform imports them into state so it can
# manage them going forward without recreating anything.
# Find all OCIDs in OCI Console → the relevant service page → click resource → OCID field.

variable "instance_ocid" {
  description = "OCID of the existing compute instance."
  type        = string
}

variable "vcn_ocid" {
  description = "OCID of the existing VCN. OCI Console → Networking → Virtual Cloud Networks."
  type        = string
}

variable "igw_ocid" {
  description = "OCID of the existing internet gateway. OCI Console → Networking → VCN → Internet Gateways."
  type        = string
}

variable "route_table_ocid" {
  description = "OCID of the existing route table used by the public subnet. OCI Console → Networking → VCN → Route Tables."
  type        = string
}

variable "security_list_ocid" {
  description = "OCID of the existing security list attached to the public subnet. OCI Console → Networking → VCN → Security Lists."
  type        = string
}

variable "subnet_ocid" {
  description = "OCID of the existing public subnet the instance is in. OCI Console → Networking → VCN → Subnets."
  type        = string
}

variable "volume_attachment_ocid" {
  description = "OCID of the existing block volume attachment. OCI Console → Compute → instance → Attached Block Volumes → volume → OCID."
  type        = string
}

variable "data_volume_ocid" {
  description = "OCID of the existing 100 GB block volume. OCI Console → Storage → Block Volumes."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key to install on the VM (the full 'ssh-ed25519 AAAA...' or 'ssh-rsa AAAA...' string). Must match ssh_private_key_path."
  type        = string
}

variable "ssh_private_key_path" {
  description = "Local path to the SSH private key. Used by Terraform's remote-exec provisioner to mount the data volume after first attach."
  type        = string
  default     = "~/.ssh/id_ed25519"
}

# ─── Networking ───────────────────────────────────────────────────────────────

variable "ssh_allowed_cidr" {
  description = "CIDR allowed on port 22. Restrict to your IP for security: e.g. '203.0.113.5/32'. Default allows all."
  type        = string
  default     = "0.0.0.0/0"
}

variable "grafana_allowed_cidr" {
  description = "CIDR allowed on port 3000 (Grafana). Restrict to your IP: e.g. '203.0.113.5/32'. Default allows all."
  type        = string
  default     = "0.0.0.0/0"
}

# ─── AWS ──────────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region for S3 and Textract. Bedrock (Claude Haiku) uses cross-region inference and does not need to match."
  type        = string
  default     = "ap-southeast-1"
}

variable "s3_bucket_name" {
  description = "Name of the existing S3 bucket for receipt images and claim PDFs. Must match AWS_S3_BUCKET in the backend config."
  type        = string
}

variable "iam_user_name" {
  description = "Name of the existing IAM user that the backend uses for S3/Textract/Bedrock access."
  type        = string
}

# ─── Infisical ────────────────────────────────────────────────────────────────

variable "infisical_client_id" {
  description = "Infisical machine identity client ID. Same value as INFISICAL_MACHINE_IDENTITY_CLIENT_ID in the backend config."
  type        = string
  sensitive   = true
}

variable "infisical_client_secret" {
  description = "Infisical machine identity client secret. Same value as INFISICAL_MACHINE_IDENTITY_CLIENT_SECRET in the backend config."
  type        = string
  sensitive   = true
}

variable "infisical_project_id" {
  description = "Infisical project ID. Same value as INFISICAL_PROJECT_ID in the backend config."
  type        = string
}

variable "infisical_env_slug" {
  description = "Infisical environment slug where AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY will be written (e.g. 'prod')."
  type        = string
  default     = "prod"
}
