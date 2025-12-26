# Static IP for GKE Ingress
resource "google_compute_global_address" "ingress_ip" {
  name = "lornu-ai-ingress-ip"
}

output "ingress_ip_address" {
  value = google_compute_global_address.ingress_ip.address
}
