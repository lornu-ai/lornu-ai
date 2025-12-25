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

# Output nameservers for domain registrar configuration
output "name_servers" {
  description = "Cloud DNS nameservers. Configure these at your domain registrar."
  value       = google_dns_managed_zone.public_zone.name_servers
}
