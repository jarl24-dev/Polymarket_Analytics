variable "credentials" {
  description = "My Credentials"
  default     = "../keys/keys.json"
}

variable "project_id" {
  description = "Project"
  default     = "PROJECT_ID_HERE"
}

variable "region" {
  description = "Region"
  #Update the below to your desired region
  default = "us-central1"
}

variable "location" {
  description = "Project Location"
  #Update the below to your desired location
  default = "US"
}

variable "bucket_name" {
  description = "My Storage Bucket Name"
  #Update the below to a unique bucket name
  default = "polymarket-analytics"
}

variable "dataset_name" {
  description = "My Bigquery Dataset Name"
  default = "polymarket"
}

