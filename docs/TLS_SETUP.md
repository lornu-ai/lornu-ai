# TLS & Let's Encrypt Setup for GKE

## Overview

This setup uses **cert-manager** to automatically provision and renew TLS certificates from Let's Encrypt using DNS-01 challenge with Google Cloud DNS.

## Prerequisites

1. **Cloud DNS Zone** - Already created via Terraform (`lornu.ai`)
2. **Service Account** - For cert-manager to manage DNS records
3. **Domain Nameservers** - Must point to Cloud DNS

## Setup Steps

### 1. Install cert-manager

cert-manager is installed via Kustomize in `k8s/base/cert-manager/`:

```bash
kubectl apply -k k8s/base/cert-manager/
```

This installs:
- cert-manager CRDs
- cert-manager controller
- ClusterIssuers for Let's Encrypt (staging & production)

### 2. Create Service Account for DNS-01 Challenge

cert-manager needs permissions to create DNS TXT records for domain validation:

```bash
# Create service account
gcloud iam service-accounts create cert-manager-dns01 \
  --display-name="cert-manager DNS-01 solver" \
  --project=gcp-lornu-ai

# Grant DNS admin role
gcloud projects add-iam-policy-binding gcp-lornu-ai \
  --member="serviceAccount:cert-manager-dns01@gcp-lornu-ai.iam.gserviceaccount.com" \
  --role="roles/dns.admin"

# Create key
gcloud iam service-accounts keys create cert-manager-key.json \
  --iam-account=cert-manager-dns01@gcp-lornu-ai.iam.gserviceaccount.com

# Create Kubernetes secret
kubectl create secret generic clouddns-dns01-solver-sa \
  --from-file=key.json=cert-manager-key.json \
  --namespace=cert-manager

# Clean up local key
rm cert-manager-key.json
```

### 3. Update Domain Nameservers

Get the Cloud DNS nameservers:

```bash
gcloud dns managed-zones describe lornu-ai-zone --format="get(nameServers)"
```

Update your domain registrar to use these nameservers.

### 4. Deploy Application with TLS

The Ingress in `k8s/base/ingress.yaml` is configured with:
- `cert-manager.io/cluster-issuer: "letsencrypt-prod"` annotation
- TLS section referencing `lornu-ai-tls` secret

When you deploy, cert-manager will automatically:
1. Create a Certificate resource
2. Request a certificate from Let's Encrypt
3. Complete DNS-01 challenge using Cloud DNS
4. Store the certificate in `lornu-ai-tls` secret
5. Configure the Ingress to use HTTPS

```bash
# Deploy to production
kubectl apply -k k8s/overlays/lornu-prod/
```

### 5. Verify Certificate

```bash
# Check certificate status
kubectl get certificate -n lornu-prod

# Check certificate details
kubectl describe certificate lornu-ai-tls -n lornu-prod

# Check cert-manager logs if issues
kubectl logs -n cert-manager -l app=cert-manager
```

## Certificate Issuers

### Staging (for testing)
- Issuer: `letsencrypt-staging`
- Use this first to avoid rate limits
- Certificates will show as untrusted in browsers

### Production
- Issuer: `letsencrypt-prod`
- Use after testing with staging
- Certificates are trusted by all browsers

## Troubleshooting

### Certificate not issuing

```bash
# Check certificate status
kubectl describe certificate lornu-ai-tls -n lornu-prod

# Check challenges
kubectl get challenges -n lornu-prod

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

### DNS-01 challenge failing

- Verify service account has `roles/dns.admin`
- Verify secret `clouddns-dns01-solver-sa` exists in cert-manager namespace
- Verify domain nameservers point to Cloud DNS

### Rate limits

Let's Encrypt has rate limits:
- 50 certificates per registered domain per week
- Use staging issuer for testing

## Automatic Renewal

cert-manager automatically renews certificates 30 days before expiration. No manual intervention needed!

## Security Notes

- Service account key is stored in Kubernetes secret
- Consider using Workload Identity instead of JSON keys (future improvement)
- Certificates are stored in Kubernetes secrets with TLS type
