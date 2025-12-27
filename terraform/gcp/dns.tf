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

# Note: If this zone already exists, import it using:
# terraform import google_dns_managed_zone.public_zone projects/gcp-lornu-ai/managedZones/lornu-ai-zone

# Dev Environment d2.lornu.ai
resource "google_dns_record_set" "dev_d2" {
  name         = "d2.${google_dns_managed_zone.public_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public_zone.name
  rrdatas      = [google_compute_global_address.ingress_ip.address]
}

# Output nameservers for domain registrar configuration
output "name_servers" {
  description = "Cloud DNS nameservers. Configure these at your domain registrar."
  value       = google_dns_managed_zone.public_zone.name_servers
}
