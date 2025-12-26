# Cloud Storage bucket for static assets (equivalent to Cloudflare R2 "Assets")
resource "google_storage_bucket" "assets" {
  name          = "${var.project_id}-assets"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  cors {
    origin          = ["https://${var.domain_name}", "https://www.${var.domain_name}"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = "production"
    purpose     = "static-assets"
  }
}

# Make assets bucket publicly readable
resource "google_storage_bucket_iam_member" "assets_public" {
  bucket = google_storage_bucket.assets.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Firestore database for rate limiting (equivalent to Cloudflare KV "RATE_LIMIT_KV")
# Note: Firestore is already provisioned, this configures it for rate limiting
resource "google_firestore_database" "rate_limit" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  # Prevent accidental deletion
  deletion_policy = "ABANDON"
}

# Create a collection for rate limiting
# This is done via application code, but we document the structure here
# Collection: rate_limits
# Document ID: {ip_address}
# Fields:
#   - count: number
#   - window_start: timestamp
#   - expires_at: timestamp
