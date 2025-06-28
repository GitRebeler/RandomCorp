# Variables for RandomCorp LKE Terraform Configuration

variable "linode_token" {
  description = "Linode API Token for authentication"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of the LKE cluster"
  type        = string
  default     = "randomcorp-lke"
}

variable "region" {
  description = "Linode region for the cluster"
  type        = string
  default     = "us-east"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "node_type" {
  description = "Linode instance type for worker nodes"
  type        = string
  default     = "g6-standard-2"
}

variable "node_count" {
  description = "Initial number of worker nodes"
  type        = number
  default     = 3
}

variable "autoscaler_min" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 3
}

variable "autoscaler_max" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 5
}

variable "enable_high_memory_pool" {
  description = "Whether to create an additional high-memory node pool"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the cluster"
  type        = list(string)
  default     = ["randomcorp", "production", "lke"]
}

variable "kubeconfig_path" {
  description = "Path where kubeconfig will be saved"
  type        = string
  default     = "~/.kube/randomcorp-lke-kubeconfig.yaml"
}

variable "create_namespace" {
  description = "Whether to create a dedicated RandomCorp namespace"
  type        = bool
  default     = false
}

# Environment-specific variables
variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}
