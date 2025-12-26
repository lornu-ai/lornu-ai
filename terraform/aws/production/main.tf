provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.lornu_cluster.cluster_name
}

provider "kubernetes" {
  host                   = module.lornu_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.lornu_cluster.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  # This provider automatically uses the configuration from the "kubernetes" provider.
}
