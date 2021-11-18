# Copyright (C) 2018 - 2020 IT Wonder Lab (https://www.itwonderlab.com)
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

# -------------------------------- WARNING --------------------------------
# IT Wonder Lab's best practices for infrastructure include modularizing 
# Terraform configuration. 
# In this example, we define everything in a single file. 
# See other tutorials for Terraform best practices for Kubernetes deployments.
# -------------------------------- WARNING --------------------------------

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.42.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }
}

data "terraform_remote_state" "aks" {
  backend = "remote"

  config = {
    organization = "greensugarcake"
    workspaces = {
      name = "provision-aks-cluster"
    }
  }
}

# Retrieve AKS cluster information
provider "azurerm" {
  features {}
}

data "azurerm_kubernetes_cluster" "cluster" {
  name                = data.terraform_remote_state.aks.outputs.kubernetes_cluster_name
  resource_group_name = data.terraform_remote_state.aks.outputs.resource_group_name
}

provider "kubernetes" {
  host = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host

  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.cluster_ca_certificate)
}


#-----------------------------------------
# KUBERNETES DEPLOYMENT COLOR APP
#-----------------------------------------

resource "kubernetes_deployment" "color" {
    metadata {
        name = var.color
        labels = {
            app   = "color"
            color = var.color
        } //labels
    } //metadata
    
    spec {
        selector {
            match_labels = {
                app   = kubernetes_deployment.color.metadata[0].labels.app
                color = var.color
            } //match_labels
        } //selector

        #Number of replicas
        replicas = 3

        #Template for the creation of the pod
        template { 
            metadata {
                labels = {
                    app   = kubernetes_deployment.color.spec.0.selector.0.match_labels.app
                    color = var.color
                } //labels
            } //metadata

            spec {
                container {
                    image = "itwonderlab/color"   #Docker image name
                    name  = var.color             #Name of the container specified as a DNS_LABEL. Each container in a pod must have a unique name (DNS_LABEL).
                    
                    #Block of string name and value pairs to set in the container's environment
                    env { 
                        name = "COLOR"
                        value = var.color
                    } //env
                    
                    #List of ports to expose from the container.
                    port { 
                        container_port = 8080
                    }//port          
                    
                    resources {
                        limits {
                            cpu    = "0.5"
                            memory = "512Mi"
                        } //limits
                        requests {
                            cpu    = "250m"
                            memory = "50Mi"
                        } //requests
                    } //resources
                } //container
            } //spec
        } //template
    } //spec
} //resource

#-------------------------------------------------
# KUBERNETES DEPLOYMENT COLOR SERVICE NODE PORT
#-------------------------------------------------

resource "kubernetes_service" "color-service" {
  metadata {
    name = var.color
  } //metadata
  spec {
    selector = {
      app = kubernetes_deployment.color.spec.0.template.0.metadata[0].labels.app
    } //selector
    //session_affinity = "ClientIP"
    port {
      port      = 8080 
      node_port = 30085
    } //port
    type = "LoadBalancer"
  } //spec
} //resource

output "lb_ip" {
  value = kubernetes_service.color-service.status.0.load_balancer.0.ingress.0.ip
}