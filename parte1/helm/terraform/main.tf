provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.default.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.default.token
  }
}

provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "test-terraform-jonathan"
    key    = "terraform/app-test/helm/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_eks_cluster" "default" {
  name = var.cluster
}

data "aws_eks_cluster_auth" "default" {
  name = var.cluster
}

resource "helm_release" "demo-app" {
  name    = "${var.service}-chart"
  chart   = "../${var.service}"
  version = var.helm_version
  wait    = false
}
