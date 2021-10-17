provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "app-challenge"
    key    = "terraform/prod/terraform.tfstate"
    region = "us-east-1"
  }
}

variable "image_tag" {
  type = string
}
locals {
  tags = {
    Managment   = "Terraform"
    Project     = "app_helloword"
    Environment = "prod"
  }
}

module "app-helloword" {
  source  = "../../modules/ecs-service"
  cluster = var.cluster
  application = {
    name        = "app-helloword"
    version     = "v1"
    environment = "prod"
  }
  container = {
    image                             = "${var.image}:${var.image_tag}" ## a setar
    cpu                               = 1024
    memory                            = 2048
    port                              = 8080
    health_check_grace_period_seconds = 300
  }
  scale = {
    cpu = 20
    min = 2
    max = 4
  }
  environment = [
    { name : "APP_PROFILE", value : "production" },
    { name : "AWS_REGION", value : "us-east-1" }
  ]

  network = {
    vpc             = var.network.vpc
    subnets         = var.network.subnets
    security_groups = var.network.security_groups
  }
  service_policy = "policies/poc.json"

  tags = local.tags

  capacity_provider = "FARGATE_SPOT"

  alb = {
    enable                     = true
    public                     = false
    certificate_domain         = ""
    idle_timeout               = 300
    health                     = "/health"
    enable_deletion_protection = true
    redirect_to_https          = true
    subnets                    = var.network.subnets
    security_groups            = var.network.security_groups
  }
}
