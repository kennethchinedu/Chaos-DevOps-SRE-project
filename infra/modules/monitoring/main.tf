resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  namespace        = "monitoring"
  create_namespace = true

  
  version = "25.21.0"
  atomic          = true
  values = [<<EOF

server:
  replicaCount: 1


alertmanager:
  enabled: true

EOF
  ]
}

resource "helm_release" "blackbox_exporter" {
  name             = "blackbox-exporter"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-blackbox-exporter"
  namespace        = "monitoring"
  create_namespace = false
  version          = "0.25.0"   


  atomic          = true
  cleanup_on_fail = true
}