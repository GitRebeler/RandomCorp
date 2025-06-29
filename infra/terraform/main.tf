# RandomCorp LKE Cluster Terraform Configuration
# This configuration creates a Linode Kubernetes Engine cluster for RandomCorp

terraform {
  required_version = ">= 1.0"
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "linode" {
  token = var.linode_token
}

# LKE Cluster
resource "linode_lke_cluster" "randomcorp" {
  k8s_version = var.k8s_version
  label       = var.cluster_name
  region      = var.region
  tags        = var.tags

  pool {
    type  = var.node_type
    count = var.node_count
    
    autoscaler {
      min = var.autoscaler_min
      max = var.autoscaler_max
    }
  }

  # Additional node pool for high-memory workloads (optional, disabled by default)
  dynamic "pool" {
    for_each = var.enable_high_memory_pool ? [1] : []
    content {
      type  = "g6-highmem-2"
      count = 1
      
      autoscaler {
        min = 1
        max = 2
      }
    }
  }
}

# Wait for cluster to be ready before generating kubeconfig
resource "time_sleep" "wait_for_cluster" {
  depends_on = [linode_lke_cluster.randomcorp]
  create_duration = "30s"
}

# Generate kubeconfig file
resource "local_file" "kubeconfig" {
  content         = base64decode(linode_lke_cluster.randomcorp.kubeconfig)
  filename        = var.kubeconfig_path
  file_permission = "0600"
  
  depends_on = [time_sleep.wait_for_cluster]
}
