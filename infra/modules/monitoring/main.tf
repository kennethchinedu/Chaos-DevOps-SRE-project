resource "helm_release" "prometheus_stack" {
  name             = "prometheus"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "82.2.0" # stable release

  # Optional: override default values
  values = [
    file("${path.module}/prometheus-values.yaml")
  ]

  atomic          = true
  cleanup_on_fail = true
  timeout         = 1100
}



# resource "helm_release" "kiali" {
#   name             = "kiali"
#   repository       = "https://kiali.org/helm-charts"
#   chart            = "kiali-server"
#   namespace        = "monitoring"
#   create_namespace = false
#   version          = "1.89.0"  

#   values = [
#     <<EOF
# auth:
#   strategy: anonymous   

# external_services:
#   prometheus:
#     url: "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:80"
#   grafana:
#     enabled: true
#     url: "http://prometheus-grafana.monitoring.svc.cluster.local:80"

# deployment:
#   accessible_namespaces:
#     - "**"

# server:
#   web_root: ""
# EOF
#   ]

#   atomic          = true
#   cleanup_on_fail = true
# }