resource "google_service_account" "dataflow_sa" {
  account_id   = "dataflow-worker-sa"
  display_name = "Service Account to run Dataflow jobs"
}

locals {
  member_dataflow_sa = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_project_iam_member" "dataflow_sa_worker" {
  member  = local.member_dataflow_sa
  project = var.project_id
  role    = "roles/dataflow.worker"
}

resource "google_bigquery_table_iam_member" "dataflow_sa_bq_editor" {
  member = local.member_dataflow_sa
  role   = "roles/bigquery.dataEditor"
  dataset_id = google_bigquery_dataset.pipeline_update.dataset_id
  table_id = google_bigquery_table.event.id
}

resource "google_pubsub_topic_iam_member" "dataflow_sa_topic_publisher" {
  member = local.member_dataflow_sa
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.event_topic.name
}

resource "google_pubsub_subscription_iam_member" "dataflow_sa_update_subscriber" {
  member       = local.member_dataflow_sa
  role         = "roles/pubsub.subscriber"
  subscription = google_pubsub_subscription.update.name
}

resource "google_pubsub_subscription_iam_member" "dataflow_sa_noupdate_subscriber" {
  member       = local.member_dataflow_sa
  role         = "roles/pubsub.subscriber"
  subscription = google_pubsub_subscription.no_update.name
}

resource "google_storage_bucket_iam_member" "dataflow_sa_temp_bucket_admin" {
  bucket = google_storage_bucket.dataflow-temp.id
  member = local.member_dataflow_sa
  role   = "roles/storage.admin"
}

resource "google_storage_bucket_iam_member" "dataflow_sa_template_bucket_viewer" {
  bucket = google_storage_bucket.data-generator-template.id
  member = local.member_dataflow_sa
  role   = "roles/storage.objectViewer"
}