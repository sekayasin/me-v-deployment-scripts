resource "google_compute_network" "vof-network" {
  name = "${var.env_name}-vof-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "vof-private-subnetwork" {
  name = "${var.env_name}-vof-private-subnetwork"
  region = "${var.region}"
  network = "${google_compute_network.vof-network.self_link}"
  ip_cidr_range = "${var.env_name == "production" ? var.ip_cidr_range : var.env_name == "staging" ? var.staging_ip_cidr_range : var.env_name == "sandbox" ? var.sandbox_ip_cidr_range : ""}"

}

resource "google_compute_subnetwork" "vof-subnetwork" {
  name = "${var.env_name}-vof-subnetwork"
  region = "${var.region}"
  network = "${google_compute_network.vof-network.self_link}"
  ip_cidr_range = "${var.env_name == "production" ? var.ip_cidr_range_next : var.env_name == "staging" ? var.staging_ip_cidr_range_next : var.env_name == "sandbox" ? var.sandbox_ip_cidr_range_next : ""}"

}

resource "google_compute_network_peering" "elk-peering" {
  name = "${var.env_name}-to-elk-peering"
  network = "${google_compute_network.vof-network.self_link}"
  peer_network = "projects/${var.project_id}/global/networks/vof-elk-network"
}

resource "google_compute_network_peering" "elk-peering-complete" {
  name = "elk-to-${var.env_name}-peering"
  network = "projects/${var.project_id}/global/networks/vof-elk-network"
  peer_network = "${google_compute_network.vof-network.self_link}"
}
