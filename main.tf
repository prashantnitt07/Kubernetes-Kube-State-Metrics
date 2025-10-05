terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "kubectl" {
  config_path = "~/.kube/config"
}



########################################
# 1 Deploy kube-state-metrics
########################################
resource "kubectl_manifest" "ksm_service_account" {
  yaml_body  = file("${path.module}/manifests/ksm_service-account.yaml")
  
}

resource "kubectl_manifest" "ksm_cluster_role" {
  yaml_body  = file("${path.module}/manifests/ksm_cluster-role.yaml")
  depends_on = [kubectl_manifest.ksm_service_account]
}

resource "kubectl_manifest" "ksm_cluster_role_binding" {
  yaml_body  = file("${path.module}/manifests/ksm_cluster-role-binding.yaml")
  depends_on = [
    kubectl_manifest.ksm_cluster_role,
    kubectl_manifest.ksm_service_account
  ]
}

resource "kubectl_manifest" "ksm_deployment" {
  yaml_body  = file("${path.module}/manifests/ksm_deployment.yaml")
  depends_on = [kubectl_manifest.ksm_cluster_role_binding]
}

resource "kubectl_manifest" "ksm_service" {
  yaml_body  = file("${path.module}/manifests/ksm_service.yaml")
  depends_on = [kubectl_manifest.ksm_deployment]
}

# Optional: force redeploy on manifest change
locals {
  ksm_hash = filesha256("${path.module}/manifests/ksm_deployment.yaml")
}

resource "null_resource" "trigger_ksm_restart" {
  triggers = {
    config_hash = local.ksm_hash
  }

  provisioner "local-exec" {
    command = "kubectl rollout restart deployment/kube-state-metrics -n kube-system || true"
  }
}
