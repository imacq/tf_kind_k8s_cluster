terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = ">= 0.6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
  }
}

# Kind Cluster Configuration
resource "kind_cluster" "cluster" {
  name           = local.cluster_name
  node_image     = "kindest/node:v${local.cluster_version}"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # Worker node configuration
    node {
      role = "worker"
      kubeadm_config_patches = [
        "kind: JoinConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      extra_port_mappings {
        container_port = 80
        host_port      = 8080
        listen_address = "0.0.0.0"
      }
    }

    # Control plane configuration
    node {
      role = "control-plane"
    }
  }
}

# Wait for the Kind cluster to be ready
resource "null_resource" "wait_for_cluster" {
  depends_on = [kind_cluster.cluster]
}

# Helm Release: Nginx Ingress Controller
resource "helm_release" "nginx_ingress" {
  depends_on = [null_resource.wait_for_cluster]

  name             = "nginx-ingress"
  repository       = var.nginx_ingress.chart_repository
  chart            = var.nginx_ingress.chart_name
  version          = var.nginx_ingress.chart_version
  namespace        = var.nginx_ingress.namespace
  create_namespace = true

  values = [templatefile("${path.root}/nginx-helm-chart-values-template.yaml", {
    ingressClassName = var.nginx_ingress.ingress_class_name
    replicas         = var.nginx_ingress.replicas
  })]
}

# Helm Release: FluxCD
resource "helm_release" "flux" {
  depends_on = [null_resource.wait_for_cluster]

  name       = "flux"
  namespace  = "flux-system"
  chart      = "flux2"
  repository = "https://fluxcd-community.github.io/helm-charts"
  version    = "2.12.0"  # Use the latest version available
  create_namespace = true

  # Installing CRDs and setting Git repository for Flux to sync from
  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "gitRepository"
    value = var.flux_git_repository
  }

  set {
    name  = "gitBranch"
    value = var.flux_git_branch
  }

  set {
    name  = "sync.interval"
    value = "1m"
  }
}

# Local variables
locals {
  cluster_name       = "cluster1"
  cluster_version    = "1.31.0"
  cluster_context    = "kind-${local.cluster_name}"
  ingress_class_name = "nginx"
}
