module "cluster_autoscaler_irsa_role" {
  count = var.create-cluster-autoscaler ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> v5.11.1"

  role_name                        = "cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [var.cluster_id]

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_issuer_arn
      namespace_service_accounts = ["kube-system:${local.clusterautoscaler.name}-sa"]
    }
  }

  tags = {
    Name           = "cluster-autoscaler"
    ServiceAccount = "cluster-autoscaler-sa"
  }
}

## create service accont and annotate with iam role
resource "kubernetes_service_account" "clusterautoscaler_serviceaccount" {
  count = var.create-cluster-autoscaler ? 1 : 0

  metadata {
    name      = "${local.clusterautoscaler.name}-sa"
    namespace = local.clusterautoscaler.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = module.cluster_autoscaler_irsa_role[0].iam_role_arn
      #"eks.amazonaws.com/role-arn" = module.cluster_autoscaler_irsa_role_with_oidc_ca[0].iam_role_arn
    }
  }
  automount_service_account_token = true

  depends_on = [module.cluster_autoscaler_irsa_role]
  #depends_on                      = [module.cluster_autoscaler_irsa_role_with_oidc_ca]
}


## apply helm chart  maintained by clusterautoscaler team
resource "helm_release" "cluster-autoscaler" {
  count = var.create-cluster-autoscaler ? 1 : 0

  name            = "cluster-autoscaler"
  repository      = "https://kubernetes.github.io/autoscaler"
  chart           = "cluster-autoscaler"
  version         = "9.23.0"
  namespace       = local.clusterautoscaler.namespace
  description     = "Cluster AutoScaler helm Chart deployment configuration."
  cleanup_on_fail = true

  set {
    name  = "rbac.serviceAccount.create"
    value = "false"
    type  = "auto"
  }
  set {
    name  = "rbac.serviceAccount.name"
    value = "${local.clusterautoscaler.name}-sa"
    type  = "string"
  }
  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_id
    type  = "string"
  }
  set {
    name  = "autoDiscovery.enabled"
    value = "true"
    type  = "auto"
  }
  set {
    name  = "awsRegion"
    value = local.aws.region
    type  = "string"
  }
  #set {
  #  name  = "serviceMonitor.enabled"
  #  value = "true"
  #}
  #set {
  #  name  = "serviceMonitor.namespace"
  #  value = "monitor"
  #}

}
