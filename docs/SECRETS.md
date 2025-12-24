# Infrastructure Secrets

The following GitHub Repository Secrets are required for the Terraform CI/CD pipeline to function correctly.

## AWS Authentication
- `AWS_ACCESS_KEY_ID`: Access Key ID for the AWS User (CI/CD Role).
- `AWS_SECRET_ACCESS_KEY`: Secret Access Key for the AWS User.

## Terraform Cloud
- `TF_API_TOKEN`: User or Team API Token for Terraform Cloud authentication.
- `TF_CLOUD_ORG`: The name of the Terraform Cloud Organization (e.g., `lornu-ai`).

## Application Secrets

### General
- `SECRETS_MANAGER_ARN_PATTERN`: ARN pattern for AWS Secrets Manager permissions (e.g., `arn:aws:secretsmanager:us-east-1:*:secret:*`).

### Production
- `PROD_DOMAIN`: The production domain name (e.g., `lornu.ai`).
- `PROD_DB_USERNAME`: Master username for the Production Aurora Database.
- `PROD_DB_PASSWORD`: Master password for the Production Aurora Database.

### Staging
- `STAGE_DOMAIN`: The staging domain name (optional/if used).
