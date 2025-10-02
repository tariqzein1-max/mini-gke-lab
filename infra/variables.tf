variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "backend_bucket" {
  type = string
}

# Naming
variable "cluster_name" {
  type    = string
  default = "autopilot-lab"
}

variable "repo_name" {
  type    = string
  default = "apps" # AR repo
}

# GitHub wiring
variable "github_owner" {
  type        = string
  description = "Your GitHub org or username"
}

variable "github_repo" {
  type        = string
  description = "Repository name"
}
