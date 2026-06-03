data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "oracle_linux_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ─── Compute Instance ─────────────────────────────────────────────────────────

import {
  to = oci_core_instance.backend
  id = var.instance_ocid
}

resource "oci_core_instance" "backend" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "reclaima-backend"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.oracle_linux_arm.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.backend.id]
    hostname_label   = "reclaima"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(file("${path.module}/templates/cloud-init.yaml"))
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      source_details[0].source_id, # Don't replace when Oracle releases new OL9 images
      availability_domain,         # Can't move ADs in-place
      metadata,                    # OCI injects extra metadata entries at provisioning time
      create_vnic_details,         # hostname_label is ForceNew — existing instance keeps its hostname.
                                   # NSG attachment: after `terraform apply`, manually attach the NSG in
                                   # OCI Console → instance → Attached VNICs → primary VNIC → Edit.
    ]
  }
}

# Data sources to read the public IP of the existing ephemeral assignment.
# The ephemeral IP (168.138.170.92) persists across reboots and stop/starts —
# it only releases on instance termination, which prevent_destroy blocks.
data "oci_core_vnic_attachments" "backend" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.backend.id
}

data "oci_core_vnic" "backend_primary" {
  vnic_id = data.oci_core_vnic_attachments.backend.vnic_attachments[0].vnic_id
}

# ─── Data Block Volume ────────────────────────────────────────────────────────

import {
  to = oci_core_volume.data
  id = var.data_volume_ocid
}

resource "oci_core_volume" "data" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "reclaima-data"
  size_in_gbs         = var.data_volume_size_gb

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [availability_domain]
  }
}

# ─── Volume Attachment ────────────────────────────────────────────────────────

import {
  to = oci_core_volume_attachment.data
  id = var.volume_attachment_ocid
}

resource "oci_core_volume_attachment" "data" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.backend.id
  volume_id       = oci_core_volume.data.id
  is_read_only    = false
  is_shareable    = true
}

# ─── Block Volume Mount ───────────────────────────────────────────────────────
# Runs once over SSH when the volume attachment is first created or replaced.
# Safe to re-run: blkid check skips formatting if filesystem already exists,
# mountpoint check skips mounting if already mounted.

resource "null_resource" "mount_data_volume" {
  triggers = {
    volume_attachment_id = oci_core_volume_attachment.data.id
  }

  connection {
    type        = "ssh"
    host        = data.oci_core_vnic.backend_primary.public_ip_address
    user        = "opc"
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "if ! sudo blkid /dev/sdb > /dev/null 2>&1; then sudo mkfs.ext4 -F /dev/sdb; fi",
      "sudo mkdir -p /mnt/data",
      "if ! mountpoint -q /mnt/data; then sudo mount /dev/sdb /mnt/data; fi",
      "grep -q '/dev/sdb' /etc/fstab || echo '/dev/sdb /mnt/data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab",
      "sudo mkdir -p /mnt/data/smart-receipt-and-warranty-manager",
      "sudo chown opc:opc /mnt/data/smart-receipt-and-warranty-manager",
    ]
  }

  depends_on = [
    oci_core_volume_attachment.data,
    data.oci_core_vnic.backend_primary,
  ]
}
