resource "google_storage_bucket" "data-generator-template" {
  location = var.region
  name = "${var.project_id}-dataflow-event-generator-template"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "event-generator-template" {
  name = "event-generator-template.json"
  bucket = google_storage_bucket.data-generator-template.name
  source = "../data-generator/event-generator-template.json"
}

resource "google_storage_bucket" "dataflow-temp" {
  name = "${var.project_id}-dataflow-temp"
  uniform_bucket_level_access = true
  location = var.region
}