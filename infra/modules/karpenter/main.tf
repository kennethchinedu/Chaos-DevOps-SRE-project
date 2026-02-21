

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}


data "aws_ecrpublic_authorization_token" "token" {
  region = "us-east-1"
}




##############
resource "aws_iam_role" "karpenter_node_role" {
  name = "karpenter-node-role-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}



resource "aws_iam_role" "karpenter_controller_role" {
  name = "karpenter-controller-role-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRoleWithWebIdentity",
      Principal = { Federated = data.aws_iam_openid_connect_provider.eks.arn },
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "karpenter_controller_policy" {
  name   = "karpenter-controller-policy-${var.cluster_name}"
  path   = "/"
  policy = file("${path.module}/karpenter-controller-policy.json") # your EC2/IAM policy
}

resource "aws_iam_role_policy_attachment" "controller" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}


resource "kubernetes_namespace" "karpenter_namespace" {
  metadata { name = "karpenter" }
}

resource "kubernetes_service_account" "karpenter_service_account" {
  metadata {
    name      = "karpenter"
    namespace = kubernetes_namespace.karpenter_namespace.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller_role.arn
    }
  }
}


module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = var.cluster_name

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix   = false
  # node_iam_role_name              = "karpenter-node-role-${var.cluster_name}"
  create_pod_identity_association = true


  

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

}


resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.6.0"
  wait                = false

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    tolerations:
      - key: "karpenter.sh/controller"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
    dnsPolicy: Default
    settings:
      clusterName:  "${data.aws_eks_cluster.cluster.name}"
      clusterEndpoint: "${data.aws_eks_cluster.cluster.endpoint}"
      interruptionQueue: "${module.karpenter.queue_name}"
    webhook:
      enabled: false
    EOT
  ]
}

# resource "helm_release" "karpenter" {
#   name       = "karpenter"
#   namespace  = kubernetes_namespace.karpenter_namespace.metadata[0].name
#   repository = "oci://public.ecr.aws/karpenter"
#   chart      = "karpenter"
#   version    = "0.36.0" # or the latest version available

#   set = [ {
#     name  = "installCRDs"
#     value = "false"
#   }, {  
#     name  = "serviceAccount.create"
#     value = "false"
#   }, {
#     name  = "serviceAccount.name"
#     value = kubernetes_service_account.karpenter_service_account.metadata[0].name
#   }, {
#     name  = "settings.clusterName"
#     value = var.cluster_name
#   }, {
#     name  = "settings.clusterEndpoint"
#     value = var.cluster_endpoint
#   }
#   ]
#   wait = true
#   timeout = 600

#   depends_on = [
#     kubernetes_service_account.karpenter_service_account,
#     kubernetes_namespace.karpenter_namespace
#   ]
# }

  
