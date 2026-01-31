
output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = module.eks_al2023.cluster_endpoint
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks_al2023.cluster_name
}
