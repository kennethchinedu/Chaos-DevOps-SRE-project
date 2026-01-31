include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  service_name = basename(get_terragrunt_dir())
  environment  = basename(dirname(get_terragrunt_dir()))

  tags_map = {
    Environment = local.environment
    Project     = "NovaOps" # Adjust project name if needed
    Service     = local.service_name
    ManagedBy   = get_aws_account_alias()
  }
}

dependency "eks" {
  config_path = "../eks" # Adjust path if needed

  mock_outputs = {
    cluster_name = "cluster-xxx"
    cluster_endpoint = "clustere-xxxx"
  }
}

# # dependency "networking" {
# #     config_path = "../networking"
# # }



dependency "vpc" {
  config_path = "../../../environment/prod/networking"

    mock_outputs = {
    vpc_id       = "vpc-xxxxxx"
    public_sub1  = "subnet-xxxxxx"
    public_sub2  = "subnet-xxxxxx"
    pri_sub1     = "subnet-xxxxxx"
    pri_sub2     = "subnet-xxxxxx"
  }
}



terraform {
  source = "../../../modules/karpenter"

  extra_arguments "vars_file" {
    commands  = ["apply", "plan", "validate", "destroy"]
    arguments = ["-var-file=${get_terragrunt_dir()}/../prod.tfvars"]
  }
}

inputs = {
  tags            = local.tags_map
  # cluster_name    = dependency.eks.outputs.cluster_name
  cluster_endpoint = dependency.eks.outputs.cluster_endpoint
  cluster_region = "us-east-1"
  # karpenter_version = var.karpenter_version
}
