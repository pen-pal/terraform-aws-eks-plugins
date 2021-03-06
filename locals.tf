locals {
  name_prefix = "${var.config.product}-${var.config.environment}-${var.config.service}"
  prefix      = "${var.config.product}-${var.config.environment}"

  config = var.config

  eks = {
    cluster_id      = var.cluster_id
    oidc_issuer     = var.oidc_issuer
    oidc_issuer_arn = var.oidc_issuer_arn
  }

  clusterautoscaler = {
    namespace      = "kube-system"
    serviceaccount = "clusterautoscaler"
  }

  externalsecrets = {
    namespace      = "kube-system"
    serviceaccount = "externalsecrets-sa"
  }

  alb = {
    serviceaccount = "aws-load-balancer-controller"
    namespace      = "kube-system"
  }

  metric-server = {
    namespace      = "kube-system"
    serviceaccount = "metrics-server"
  }

  aws = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
  }
}
