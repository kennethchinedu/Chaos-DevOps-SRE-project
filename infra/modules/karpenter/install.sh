# # Register IAM role as EC2 principal
# aws eks create-access-entry \
#   --cluster-name prod-eks2 \
#   --principal-arn arn:aws:iam::<account-id>:role/karpenter-node-role-prod-eks2 \
#   --type EC2_LINUX

# # Attach compute policy so node can bootstrap
# aws eks associate-access-policy \
#   --cluster-name prod-eks2 \
#   --principal-arn arn:aws:iam::<account-id>:role/karpenter-node-role-prod-eks2 \
#   --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSComputeClusterPolicy \
#   --access-scope type=cluster


# helm repo add karpenter https://charts.karpenter.sh
# helm repo update

# # Install only CRDs first
# helm install karpenter-crds karpenter/karpenter \
#   --namespace karpenter --create-namespace \
#   --set installCRDs=true \
#   --set serviceAccount.create=false


# kubectl apply -f https://github.com/aws/karpenter/releases/latest/download/karpenter-crds.yaml

#Label nodes
kubectl label node <node> karpenter.sh/controller=true



kubectl get nodes --show-labels | grep karpenter
