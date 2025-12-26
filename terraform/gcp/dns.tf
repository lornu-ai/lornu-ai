# Public DNS Zone for lornu.ai
# Used for public DNS records and Let's Encrypt DNS-01 validation
resource "google_dns_managed_zone" "public_zone" {
  name        = "lornu-ai-zone"
  dns_name    = "lornu.ai."
  description = "Public zone for lornu.ai"
  visibility  = "public"

  labels = {
    environment = "production"
    managed-by  = "terraform"
  }
}

# Import the existing manually created zone
import {
  to = google_dns_managed_zone.public_zone
  id = "projects/gcp-lornu-ai/managedZones/lornu-ai-zone"
}

# Dev Environment d2.lornu.ai
resource "google_dns_record_set" "dev_d2" {
  name         = "d2.${google_dns_managed_zone.public_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public_zone.name
  rrdatas      = ["34.49.129.46"] # GKE Ingress IP for lornu-dev
}

# Output nameservers for domain registrar configuration
output "name_servers" {
  description = "Cloud DNS nameservers. Configure these at your domain registrar."
  value       = google_dns_managed_zone.public_zone.name_servers
}
