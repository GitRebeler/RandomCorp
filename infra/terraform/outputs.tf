# Outputs for RandomCorp LKE Terraform Configuration

output "cluster_id" {
  description = "ID of the created LKE cluster"
  value       = linode_lke_cluster.randomcorp.id
}

output "cluster_label" {
  description = "Label of the created LKE cluster"
  value       = linode_lke_cluster.randomcorp.label
}

output "cluster_region" {
  description = "Region of the created LKE cluster"
  value       = linode_lke_cluster.randomcorp.region
}

output "cluster_status" {
  description = "Status of the created LKE cluster"
  value       = linode_lke_cluster.randomcorp.status
}

output "cluster_api_endpoints" {
  description = "API endpoints of the created LKE cluster"
  value       = linode_lke_cluster.randomcorp.api_endpoints
}

output "cluster_dashboard_url" {
  description = "Dashboard URL of the created LKE cluster"
  value       = linode_lke_cluster.randomcorp.dashboard_url
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Path to the generated kubeconfig file"
  value       = local_file.kubeconfig.filename
}

output "node_pools" {
  description = "Information about the cluster node pools"
  value = [
    for pool in linode_lke_cluster.randomcorp.pool : {
      type       = pool.type
      count      = pool.count
      autoscaler = pool.autoscaler
    }
  ]
}

# Helpful commands for next steps
output "kubectl_config_command" {
  description = "Command to set KUBECONFIG environment variable"
  value       = "export KUBECONFIG=${local_file.kubeconfig.filename}"
}

output "cluster_info_command" {
  description = "Command to view cluster information"
  value       = "kubectl cluster-info"
}
