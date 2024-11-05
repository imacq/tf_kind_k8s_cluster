terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = ">= 0.6.0"
    }
    flux = {
      source = "fluxcd/flux"
      version = "1.3.0"
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

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready node --all --timeout=300s"
  }
}

# FluxCD bootstrap

/*
resource "github_repository" "this" {
  name        = var.github_repository
  description = var.github_repository
  visibility  = "private"
  auto_init   = false # This is extremely important as flux_bootstrap_git will not work without a repository that has been initialised
}
*/

resource "flux_bootstrap_git" "this" {
  depends_on = [null_resource.wait_for_cluster]

  embedded_manifests = true
  path               = "clusters/my-cluster"
  namespace          = "flux-system"
}

# Local variables
locals {
  cluster_name       = "cluster1"
  cluster_version    = "1.31.0"
  cluster_context    = "kind-${local.cluster_name}"
  ingress_class_name = "nginx"
}
