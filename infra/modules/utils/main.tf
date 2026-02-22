#  Cert-Manager
# resource "helm_release" "cert_manager" {
#   name             = "cert-manager"
#   repository       = "https://charts.jetstack.io"
#   chart            = "cert-manager"
#   namespace        = "cert-manager"
#   create_namespace = true

#   set = [ {
#     name  = "installCRDs"
#     value = "true"
#   }
#   ]
  
# }



#Argocd
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
}


#Istio
resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
}
    
#istiod
resource "helm_release" "istiod" {
  name             = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  namespace        = "istio-system"
  create_namespace = true

  depends_on = [
    helm_release.istio_base
  ]
}


#istiod
resource "helm_release" "istiod_cni" {
  name             = "istio-cni"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "cni"
  namespace        = "istio-system"
  create_namespace = true

  depends_on = [
    helm_release.istio_base
  ]
}

#istio gateway
resource "helm_release" "istio_gateway" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-system"
  create_namespace = true

  depends_on = [
    helm_release.istiod
  ]

}



###########################################################################
#.        CHAOS MESH
#####################################


resource "helm_release" "chaos_mesh" {
  name = "chaos-mesh"
  repository = "https://charts.chaos-mesh.org"
  chart = "chaos-mesh"
  namespace = "chaos-mesh"
  create_namespace = true
  version = "2.8.1"

  atomic = true
  timeout = 300

}


# ################# MONITORING STACK INSTALLATION #################
# #To keep things simple we will be installing manifest for out monitoring stack directly

# resource "null_resource" "istio_grafana" {
#   provisioner "local-exec" {
#     command = "kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/addons/grafana.yaml"
#   }
# }

# resource "null_resource" "istio_prometheus" {
#   provisioner "local-exec" {
#     command = "kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/addons/prometheus.yaml"
#   }
# }

# resource "null_resource" "istio_kiali" {
#   provisioner "local-exec" {
#     command = "kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/addons/kiali.yaml"
#   }
# }


# # Rancher
# resource "helm_release" "rancher" {
#    name             = "rancher"
#    repository       = "https://releases.rancher.com/server-charts/latest"
#    chart            = "rancher"
#    namespace        = "cattle-system"
#    create_namespace = true

#    set =[ {
#      name  = "hostname"
#      value = "sample-domain.com"
#    }
#    , {
#      name  = "ingress.tls.source"
#      value = "rancher"
#      }
#    ]
#    depends_on = [ helm_release.cert_manager ]
#  }

 