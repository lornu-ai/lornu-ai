module "eso_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name = "lornu-ai-prod-external-secrets"

  role_policy_arns = {
    policy = aws_iam_policy.eso.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }

  tags = {
    Environment = "production"
    GithubRepo  = "lornu-ai"
  }
}

resource "aws_iam_policy" "eso" {
  name        = "lornu-ai-prod-external-secrets-policy"
  description = "Policy for External Secrets Operator to access Secrets Manager"
  policy      = data.aws_iam_policy_document.eso.json
}

data "aws_iam_policy_document" "eso" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:lornu-ai-*"
    ]
  }
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  version          = "0.9.13" # Pin version
  depends_on       = [module.eks]

  timeouts {
    create = "10m"
    update = "10m"
  }

  values = [
    yamlencode({
      installCRDs = true
      serviceAccount = {
        name = "external-secrets"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.eso_role.iam_role_arn
        }
      }
    })
  ]
}
