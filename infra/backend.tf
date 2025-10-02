terraform {
  backend "gcs" {
    bucket = "single-clock-473907-p6-tf-state" # your bucket name
    prefix = "terraform/state"
  }
}
