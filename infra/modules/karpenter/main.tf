

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}


data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}


data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}


#Karpenter role
resource "aws_iam_role" "karpenter_node_role" {
  name = "karpenter-controller-role-${var.cluster_name}"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "ec2.${data.aws_partition.current.dns_suffix}"
        }
      },
    ]
  })

  tags = merge(
    var.tags,
    { Name = "${var.tags["Environment"]}-karpenter-role" }
  )
}


resource "aws_iam_policy_attachment" "cni_attachement" {
  name       = "cni-attachment"
  roles      = [aws_iam_role.karpenter_node_role.name]
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
}


resource "aws_iam_policy_attachment" "workers_attachement" {
  name       = "workers-attachment"
  roles      = [aws_iam_role.karpenter_node_role.name]
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}


resource "aws_iam_policy_attachment" "registery_attachement" {
  name       = "registery-attachment"
  roles      = [aws_iam_role.karpenter_node_role.name]
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_policy_attachment" "ssm_attachement" {
  name       = "ssm-attachment"
  roles      = [aws_iam_role.karpenter_node_role.name]
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}



resource "aws_iam_role" "karpenter_controller_role" {
  name = "karpenter-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
          }
        }
      }
    ]
  })
}




resource "aws_iam_policy" "karpenter_controller_policy" {
  name        = "karpenter-controller-instance-policy-${var.cluster_name}"
  path        = "/"
  description = "IAM policy for Karpenter controller to manage EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
        ],
        Effect   = "Allow",
        Resource = "*",
        Sid      = "Karpenter"
      },
      {
        Action = "ec2:TerminateInstances",
        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/nodepool": "*"
          }
        },
        Effect   = "Allow",
        Resource = "*",
        Sid      = "ConditionalEC2Termination"
      },
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/KarpenterNodeRole-${var.cluster_name}",
        Sid      = "PassNodeIAMRole"
      },
      {
        Effect   = "Allow",
        Action   = "eks:DescribeCluster",
        Resource = "*",
        Sid      = "EKSClusterEndpointLookup"
      },
      {
        Sid      = "AllowScopedInstanceProfileCreationActions",
        Effect   = "Allow",
        Resource = "*",
        Action = [
          "iam:CreateInstanceProfile"
        ],
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
            "aws:RequestTag/topology.kubernetes.io/region": var.cluster_region
          },
          StringLike = {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass": "*"
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileTagActions",
        Effect   = "Allow",
        Resource = "*",
        Action = [
          "iam:TagInstanceProfile"
        ],
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
            "aws:ResourceTag/topology.kubernetes.io/region": var.cluster_region,
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
            "aws:RequestTag/topology.kubernetes.io/region": var.cluster_region
          },
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass": "*",
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass": "*"
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileActions",
        Effect   = "Allow",
        Resource = "*",
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:ListInstanceProfiles"  # <-- ADDED THIS LINE
        ],
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
            "aws:ResourceTag/topology.kubernetes.io/region": var.cluster_region
          },
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass": "*"
          }
        }
      },
      {
        Sid      = "AllowInstanceProfileReadActions",
        Effect   = "Allow",
        Resource = "*",
        Action   = "iam:GetInstanceProfile"
      },
      {
        Effect   = "Allow",
        Action   = "iam:CreateServiceLinkedRole",
        Resource = "arn:${data.aws_partition.current.partition}:iam::*:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot",
        Sid      = "CreateServiceLinkedRoleForEC2Spot"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}



# karpenter oci://public.ecr.aws/karpenter/karpenter
#install karpenter

resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }
}


resource "kubernetes_service_account" "karpenter" {
  metadata {
    name      = "karpenter"
    namespace = kubernetes_namespace.karpenter.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller_role.arn
    }
  }
}


resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version
  namespace  = "karpenter"
  create_namespace = false

  set = [
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account.karpenter.metadata[0].name
    },
    {
      name  = "settings.clusterEndpoint"
      value = var.cluster_endpoint
    },
    {
      name  = "settings.clusterName"
      value = var.cluster_name
    }
  ]

  depends_on = [
    kubernetes_service_account.karpenter
  ]
}
