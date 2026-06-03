import {
  to = oci_core_vcn.main
  id = var.vcn_ocid
}

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "reclaima-vcn"
  dns_label      = "vcn01091345"

  lifecycle {
    # dns_label is ForceNew in OCI — changing it would destroy and recreate
    # the VCN (and cascade into every resource inside it). Keep the original.
    ignore_changes = [dns_label]
  }
}

import {
  to = oci_core_internet_gateway.main
  id = var.igw_ocid
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "reclaima-igw"
  enabled        = true
}

import {
  to = oci_core_route_table.public
  id = var.route_table_ocid
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "reclaima-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

import {
  to = oci_core_security_list.public
  id = var.security_list_ocid
}

# Shared security list — contains rules for other projects on this VM.
# Terraform tracks its existence; rule changes are managed manually in OCI Console.
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "reclaima-public-sl"

  lifecycle {
    ignore_changes = [ingress_security_rules, egress_security_rules]
  }
}

import {
  to = oci_core_subnet.public
  id = var.subnet_ocid
}

resource "oci_core_subnet" "public" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.main.id
  cidr_block        = "10.0.0.0/24"
  display_name      = "reclaima-public-subnet"
  dns_label         = "subnet01091345"
  route_table_id    = oci_core_route_table.public.id
  security_list_ids = [oci_core_security_list.public.id]

  lifecycle {
    # dns_label and cidr_block are both ForceNew — keep originals.
    ignore_changes = [dns_label, cidr_block]
  }
}
