provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "test-terraform-jonathan"
    key    = "terraform/app-test/terraform.tfstate"
    region = "us-east-1"
  }
}

variable "image" {
  type = string
}

variable "image_tag" {
  type = string
}

locals {
  internal_network = {
    security_groups = ["sg-027cd102287e7a561"]
  }
  tags = {
    Managment   = "Terraform"
    Project     = "app_poc_waf"
    Environment = "prod"
  }
}

module "network" {
  source                                      = "../../modules/network"
  name_prefix                                 = "poc-networking"
  vpc_cidr_block                              = "192.168.0.0/16"
  availability_zones                          = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  public_subnets_cidrs_per_availability_zone  = ["192.168.0.0/19", "192.168.32.0/19", "192.168.64.0/19", "192.168.96.0/19"]
  private_subnets_cidrs_per_availability_zone = ["192.168.128.0/19", "192.168.160.0/19", "192.168.192.0/19", "192.168.224.0/19"]
}

module "cluster" {
  source = "../../modules/ecs-cluster"
  name   = "helloworld-cluster"
}

module "app-helloworld" {
  source  = "../../modules/ecs-service"
  cluster = module.cluster.aws_ecs_cluster_cluster_name
  application = {
    name        = "app-helloworld"
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
    vpc             = module.network.vpc_id
    subnets         = module.network.private_subnets_ids
    security_groups = local.internal_network.security_groups
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
    subnets                    = module.network.private_subnets_ids
    security_groups            = local.internal_network.security_groups
  }
}
