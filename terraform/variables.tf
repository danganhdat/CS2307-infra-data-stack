variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type    = string
  default = "asia-southeast2"
}

variable "zone" {
  type    = string
  default = "asia-southeast2-a"
}

variable "machine_type" {
  type    = string
  default = "e2-standard-4" # 4 vCPU / 16 GB — comfortable for all three
}

variable "data_disk_gb" {
  type    = number
  default = 100
}

variable "github_repo" {
  type        = string
  description = "owner/repo allowed to deploy via Workload Identity Federation, e.g. myuser/infra-data-stack. Exact match required — no '.git' suffix or 'https://' prefix."
}

variable "allowed_source_ranges" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to reach the service ports. Set to your IP (e.g. [\"1.2.3.4/32\"]) to lock it down."
}
