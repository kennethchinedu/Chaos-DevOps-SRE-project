variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_region" {
  type = string 
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "karpenter_version" {
  type = string
  default = "1.8.6"
}

variable "oidc" {
  type = string
}