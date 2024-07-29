resource "google_service_account" "nodeapp_appengine_service_account" {
  account_id   = "nodeapp_appengine_service_account"
  display_name = "Custom App Engine Service Account for NodeApp !"
}

resource "google_project_iam_member" "nodeapp_gae_api" {
  project = google_service_account.nodeapp_appengine_service_account.project
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${google_service_account.nodeapp_appengine_service_account.email}"
}

resource "google_project_iam_member" "nodeapp_storage_viewer" {
  project = google_service_account.nodeapp_appengine_service_account.project
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.nodeapp_appengine_service_account.email}"
}

resource "google_storage_bucket" "nodeapp_bucket" {
  name     = "nodeapp_bucket"
  location = "us-central1"
}

resource "google_storage_bucket_object" "nodeapp_object" {
  name          = "nodeapp.zip"
  storage_class = "REGIONAL"
  bucket        = google_storage_bucket.nodeapp_bucket.name
  source        = "./nodeapp.zip"
}

resource "google_app_engine_standard_app_version" "nodeapp_appengine_version" {
  version_id                = "v2"
  service                   = "nodeapp"
  runtime                   = "nodejs20"
  app_engine_apis           = true
  delete_service_on_destroy = true

  entrypoint {
    shell = "node server.mjs"
  }

  deployment {
    zip {
      source_url = "https://storage.googleapis.com/${google_storage_bucket.nodeapp_bucket.name}/${google_storage_bucket_object.nodeapp_object.name}"
    }
  }

  env_variables = {
    port = "8080"
  }

  basic_scaling {
    max_instances = 5
  }

  automatic_scaling {
    max_concurrent_requests = 10
    min_idle_instances      = 1
    max_idle_instances      = 3
    min_pending_latency     = "1s"
    max_pending_latency     = "5s"
    standard_scheduler_settings {
      target_cpu_utilization        = 0.5
      target_throughput_utilization = 0.75
      min_instances                 = 2
      max_instances                 = 10
    }
  }

  noop_on_destroy = false
  service_account = google_service_account.nodeapp_appengine_service_account.email
}

