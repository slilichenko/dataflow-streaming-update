resource "google_pubsub_topic" "event_topic" {
  name = "network-event"
}

output "event-topic" {
  value = google_pubsub_topic.event_topic.id
}

resource "google_pubsub_subscription" "update" {
  name = "network-event-update"
  topic = google_pubsub_topic.event_topic.name
}

resource "google_pubsub_subscription" "no_update" {
  name = "network-event-no-update"
  topic = google_pubsub_topic.event_topic.name
}

