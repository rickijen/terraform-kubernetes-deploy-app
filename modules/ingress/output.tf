output "agic_ip" {
  value = kubernetes_ingress.ingress.status.0.load_balancer.0.ingress.0.ip
}