# Static external IP so the address stays the same across VM restarts.
resource "google_compute_address" "public" {
  name   = "data-vm-ip"
  region = var.region
}

# Opens the service ports for direct IP:port access.
#   5432 Postgres | 7474 Neo4j Browser | 7687 Bolt | 8080 pgAdmin | 9000 MinIO S3 | 9001 MinIO Console
#
# By default this is open to the whole internet. That is convenient but risky —
# Postgres especially gets scanned constantly. STRONGLY recommended: set
# allowed_source_ranges to your own IP in terraform.tfvars, e.g.
#   allowed_source_ranges = ["203.0.113.7/32"]
# (find yours with: curl ifconfig.me)
resource "google_compute_firewall" "services" {
  name      = "allow-services"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["5432", "7474", "7687", "8080", "9000", "9001"]
  }
  source_ranges = var.allowed_source_ranges
}

output "public_ip" {
  description = "Reach services at this IP, e.g. http://<public_ip>:9001 for MinIO console"
  value       = google_compute_address.public.address
}
