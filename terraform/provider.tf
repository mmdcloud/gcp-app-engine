terraform {
  required_providers {
    aws = {
      source  = "hashicorp/google"
      version = "5.38.0"
    }
  }
}

# Configure the Google Provider
provider "google" {
  region = "us-central1"
}
