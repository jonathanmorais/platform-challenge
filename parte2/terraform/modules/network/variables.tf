variable "name_prefix" {
}

variable "vpc_cidr_block" {
}

variable "availability_zones" {
  type = list(any)
}

variable "public_subnets_cidrs_per_availability_zone" {
  type = list(any)
}

variable "private_subnets_cidrs_per_availability_zone" {
  type = list(any)
}

variable "single_nat" {
  type    = bool
  default = false
}

variable "additional_tags" {
  default = {}
  type    = map(string)
}
