provider "kubernetes" {
  # Docs: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
  config_path    = "~/.kube/config"
  config_context = local.cluster_context
}

provider "flux" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = local.cluster_context
  }
  git = {
    url = "https://github.com/${var.github_org}/${var.github_repository}.git"
    http = {
      username = "imacq" # This can be any string when using a personal access token
      password = var.github_token
    }
  }
}

/*provider "github" {
  owner = var.github_org
  token = var.github_token
}*/

provider "kind" {}