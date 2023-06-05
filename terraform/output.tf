output "project_id" {
  value = var.project_id
}

output "region" {
  value = var.region
}

output "event-generator-template" {
  value = "gs://${google_storage_bucket_object.event-generator-template.bucket}/${google_storage_bucket_object.event-generator-template.name}"
}

output "dataflow-temp-bucket" {
  value = "gs://${google_storage_bucket.dataflow-temp.name}"
}

output "bq-dataset" {
  value = google_bigquery_dataset.pipeline_update.dataset_id
}

output "table-name" {
  value = google_bigquery_table.event.table_id
}

output "event-update-sub" {
  value = google_pubsub_subscription.update.id
}

output "event-no-update-sub" {
  value = google_pubsub_subscription.no_update.id
}

output "dataflow-sa" {
  value = google_service_account.dataflow_sa.email
}