output "vm_name" {
  value = google_compute_instance.vm.name
}

output "zone" {
  value = var.zone
}

# Paste these two into GitHub → Settings → Secrets and variables → Actions
output "wif_provider" {
  description = "Set as GitHub secret WIF_PROVIDER"
  value       = google_iam_workload_identity_pool_provider.gh.name
}

output "deployer_sa" {
  description = "Set as GitHub secret DEPLOYER_SA"
  value       = google_service_account.deployer.email
}
