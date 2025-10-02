########################################
# Enable required GCP APIs (safe to re-run)
########################################
resource "google_project_service" "services" {
  for_each = toset([
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

########################################
# GKE Autopilot Cluster
########################################
resource "google_container_cluster" "this" {
  name                = var.cluster_name
  location            = var.region
  enable_autopilot    = true
  deletion_protection = false

  release_channel { channel = "REGULAR" }
  depends_on = [google_project_service.services]
}

########################################
# Artifact Registry (Docker)
########################################
resource "google_artifact_registry_repository" "apps" {
  location      = var.region
  repository_id = var.repo_name
  description   = "App images"
  format        = "DOCKER"
  depends_on    = [google_project_service.services]
}

########################################
# Service Account used by GitHub Actions to deploy
########################################
resource "google_service_account" "deployer" {
  account_id   = "gh-deployer"
  display_name = "GitHub Actions Deployer"
}

# Minimal roles for the lab (broad on purpose)
resource "google_project_iam_member" "deployer_roles" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/container.admin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/viewer",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

########################################
# Workload Identity Federation (GitHub OIDC)
########################################
########################################
# Workload Identity Federation (GitHub OIDC)
########################################
resource "google_iam_workload_identity_pool" "gh_pool" {
  workload_identity_pool_id = "github-pool-2"
  display_name              = "GitHub Pool"
}

# Provider (maps claims; includes a repo-only condition to satisfy API quirks)
resource "google_iam_workload_identity_pool_provider" "gh_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.gh_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider-2"
  display_name                       = "GitHub Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # keep this to match what we’ll create/import so TF sees no drift
  attribute_condition = "attribute.repository=='${var.github_owner}/${var.github_repo}'"

  oidc { issuer_uri = "https://token.actions.githubusercontent.com" }
}


# TEMPORARILY COMMENT THIS OUT FOR STEP 1
# resource "google_service_account_iam_member" "wif_bind" {
#   service_account_id = google_service_account.deployer.name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gh_pool.name}/attribute.repository/${var.github_owner}/${var.github_repo}"
# }

########################################
# Outputs
########################################
output "cluster_name" { value = google_container_cluster.this.name }
output "cluster_region" { value = var.region }
output "deployer_sa" { value = google_service_account.deployer.email }
output "wif_provider" { value = google_iam_workload_identity_pool_provider.gh_provider.name }
output "ar_repo" { value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.apps.repository_id}" }
