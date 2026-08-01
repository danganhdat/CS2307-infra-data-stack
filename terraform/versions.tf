terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Strongly recommended: keep state in GCS, not on your laptop.
  # It contains the generated DB passwords. Create the bucket first, then
  # uncomment and run `terraform init -migrate-state`.
  # backend "gcs" {
  #   bucket = "YOUR_TF_STATE_BUCKET"
  #   prefix = "data-stack"
  # }
}
