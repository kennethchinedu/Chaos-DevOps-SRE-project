#Prometheus installation

resource "helm_release" "prometheus_server" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  # Optional: override values
  values = [
    file("values.yaml")
  ]

  
  timeout = 600
#   atomic  = true
}


resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("values.yaml")
  ]

#   atomic  = true
  timeout = 300
}

