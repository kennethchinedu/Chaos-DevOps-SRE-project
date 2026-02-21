# =============================
# EKS Cluster Module
# =============================

data "aws_caller_identity" "current" {}



module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.tags["Environment"]}-eks2"
  kubernetes_version = "1.33"

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }

  endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.public_subnet_ids

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    "${var.tags["Environment"]}" = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 5
      desired_size = 2

      labels = {
        "karpenter.sh/controller" = "true"
      }

      taints = {
        karpenter = {
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = "${var.tags["Environment"]}-eks2"
  }

  tags = {
    Environment = var.tags["Environment"]
    Terraform   = "true"
  }
}







# # =============================
# # Security Group for Nodes
# # =============================
# resource "aws_security_group" "k8s_node_sg" {
#   name        = "${var.tags["Environment"]}-eks2-nodes-sg"
#   description = "EKS worker nodes security group"
#   vpc_id      = var.vpc_id

#   tags = {
#     Environment = var.tags["Environment"]
#     Team        = "DevOps"
#     Terraform   = "true"
#     "kubernetes.io/cluster/${module.eks_al2023.cluster_name}" = "owned"
#     "karpenter.sh/discovery" = module.eks_al2023.cluster_name
#   }
# }

# # =============================
# # Node Security Group Rules
# # =============================

# resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
#   security_group_id = aws_security_group.k8s_node_sg.id
#   cidr_ipv4         = var.vpc_cidr
#   from_port         = 22
#   ip_protocol       = "tcp"
#   to_port           = 22
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic" {
#   security_group_id = aws_security_group.k8s_node_sg.id
#   cidr_ipv4         = var.vpc_cidr
#   ip_protocol       = "-1"
#   description       = "Allow all traffic to the node security group"
#   # referenced_security_group_id = module.eks_al2023.cluster_security_group_id
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
#   security_group_id = aws_security_group.k8s_node_sg.id
#   cidr_ipv4         = var.vpc_cidr
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
#   # referenced_security_group_id = module.eks_al2023.cluster_security_group_id
#   description       = "Allow HTTPS traffic to the node security group"
# }


# resource "aws_vpc_security_group_ingress_rule" "allow_cluster_to_nodes_https" {
#   security_group_id            = aws_security_group.k8s_node_sg.id
#   referenced_security_group_id = module.eks_al2023.cluster_security_group_id
#   from_port                    = 443
#   to_port                      = 443
#   ip_protocol                  = "tcp"
#   description                  = "Allow EKS control plane to communicate with nodes on HTTPS"
# }



# # resource "aws_eks_access_entry" "karpenter_nodes" {
# #   cluster_name  = module.eks_al2023.cluster_name
# #   principal_arn = "arn:aws:iam::471112894147:role/karpenter-controller-role-prod-eks2"
# #   type          = "EC2_LINUX"
# # }
