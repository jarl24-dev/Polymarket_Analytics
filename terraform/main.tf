terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.26.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials)
}

resource "google_storage_bucket" "project-bucket" {
  name          = "${var.project_id}-${var.bucket_name}"
  location      = var.location
  force_destroy = true

  public_access_prevention = "enforced"

  storage_class = "STANDARD"

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_bigquery_dataset" "project_dataset_staging" {
  dataset_id = "${var.dataset_name}_staging"
  location   = var.location
}

resource "google_bigquery_dataset" "project_dataset_intermediate" {
  dataset_id = "${var.dataset_name}_intermediate"
  location   = var.location
}

resource "google_bigquery_dataset" "project_dataset_marts" {
  dataset_id = "${var.dataset_name}_marts"
  location   = var.location
}
