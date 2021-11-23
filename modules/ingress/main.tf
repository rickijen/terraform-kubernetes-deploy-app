# AGIC Ingress
resource "kubernetes_ingress" "ingress" {
  wait_for_load_balancer = true
  metadata {
    name = var.k8s_ingress_name
    annotations = {
      "kubernetes.io/ingress.class" = var.ingress_class
    }
  }
  spec {
    rule {
      http {
        path {
          path = "/${var.service_name}"
          #path = "/"
          backend {
            service_name = var.service_name
            service_port = var.service_port
          }
        }
      }
    }
  }
}
