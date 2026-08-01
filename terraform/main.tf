provider "google" {
  project = var.project_id
  region  = var.region
}

# ============================================================
# Networking — dedicated VPC, private subnet, Cloud NAT
# ============================================================
resource "google_compute_network" "vpc" {
  name                    = "data-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "data-subnet"
  ip_cidr_range            = "10.10.0.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}

# ============================================================
# Firewall — IAP-only SSH, internal-only service ports
# ============================================================
resource "google_compute_firewall" "iap_ssh" {
  name      = "allow-iap-ssh"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  # IAP's published range. Lets you SSH without exposing 22 to the internet.
  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "internal" {
  name      = "allow-internal"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["5432", "7474", "7687", "9000", "9001"]
  }
  source_ranges = ["10.10.0.0/24"]
}

# ============================================================
# Secrets — generated once, stored in Secret Manager
# ============================================================
resource "random_password" "pg" {
  length  = 24
  special = false
}
resource "random_password" "neo4j" {
  length  = 24
  special = false
}
resource "random_password" "minio" {
  length  = 24
  special = false
}
resource "random_password" "pgadmin" {
  length  = 24
  special = false
}

locals {
  secrets = {
    postgres-password = random_password.pg.result
    neo4j-password    = random_password.neo4j.result
    minio-password    = random_password.minio.result
    pgadmin-password  = random_password.pgadmin.result
  }
}

resource "google_secret_manager_secret" "s" {
  for_each  = local.secrets
  secret_id = each.key
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "v" {
  for_each    = local.secrets
  secret      = google_secret_manager_secret.s[each.key].id
  secret_data = each.value
}

# ============================================================
# VM service account — read secrets only
# ============================================================
resource "google_service_account" "vm" {
  account_id   = "data-vm-sa"
  display_name = "Data stack VM"
}

resource "google_secret_manager_secret_iam_member" "vm_access" {
  for_each  = google_secret_manager_secret.s
  secret_id = each.value.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm.email}"
}

# ============================================================
# Data disk (persists independently of the VM) + VM
# ============================================================
resource "google_compute_disk" "data" {
  name = "data-disk"
  type = "pd-ssd"
  zone = var.zone
  size = var.data_disk_gb
}

resource "google_compute_instance" "vm" {
  name         = "data-vm"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 30
      type  = "pd-balanced"
    }
  }

  attached_disk {
    source      = google_compute_disk.data.id
    device_name = "data-disk" # startup.sh looks for /dev/disk/by-id/google-data-disk
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
      nat_ip = google_compute_address.public.address # static public IP
    }
  }

  service_account {
    email  = google_service_account.vm.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = file("${path.module}/../scripts/startup.sh")

  allow_stopping_for_update = true
}

# ============================================================
# GitHub Actions deployer — keyless auth via Workload Identity
# ============================================================
resource "google_service_account" "deployer" {
  account_id   = "gh-deployer"
  display_name = "GitHub Actions deployer"
}

# Enough to scp/ssh to the VM through IAP.
resource "google_project_iam_member" "deployer_roles" {
  for_each = toset([
    "roles/compute.instanceAdmin.v1",
    "roles/iap.tunnelResourceAccessor",
    "roles/iam.serviceAccountUser",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

resource "google_iam_workload_identity_pool" "gh" {
  workload_identity_pool_id = "github-pool"
}

resource "google_iam_workload_identity_pool_provider" "gh" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.gh.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Critical: only tokens from your repo may impersonate the deployer.
  attribute_condition = "assertion.repository == \"${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "wif_bind" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gh.name}/attribute.repository/${var.github_repo}"
}
