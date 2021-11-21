variable "ingress_class" {
    type = string
    description = "Ingress Class"
}

variable "k8s_ingress_name" {
    type = string
    description = "Name of ingress"
}

variable "service_name" {
    type = string
    description = "Name of service"
}

variable "service_port" {
    type = number
    description = "Service port"
}