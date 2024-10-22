# Nginx Ingress Variables
variable "nginx_ingress" {
  description = "Variables set for deployment of Nginx Ingress Controller."
  type = object({
    namespace          = string
    replicas           = number
    ingress_class_name = string
    chart_repository   = string
    chart_name         = string
    chart_version      = string
  })
  default = {
    namespace          = "nginx-ingress"
    replicas           = 1
    ingress_class_name = "nginx"
    chart_repository   = "https://kubernetes.github.io/ingress-nginx"
    chart_name         = "ingress-nginx"
    chart_version      = "4.11.2"
  }
}

# FluxCD Variables
variable "flux_git_repository" {
  description = "Git repository URL where Flux will sync the Kubernetes manifests"
  type        = string
  default     = "https://github.com/your-org/your-repo"  # Update with your repository
}

variable "flux_git_branch" {
  description = "Branch in the repository where Flux should sync from"
  type        = string
  default     = "main"
}
