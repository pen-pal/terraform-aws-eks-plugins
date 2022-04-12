terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

locals {
  component   = "metric-server"
  name_prefix = "${var.config.product}-${var.config.environment}-${var.config.service}-${local.component}"

  config = var.config

  eks = {
    cluster_id = var.eks.cluster_id
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

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


############################################
# Metric Server Helm
############################################
resource "helm_release" "metricsserver" {
  count = creat_metricserver ? 1 : 0

  name       = "metricsserveer"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.8.2"
  namespace  = local.metric-server.namespace

  set {
    name  = "metrics.enabled"
    value = "true"
  }

  set {
    name  = "serviceeMonitor.enabled"
    value = "true"
  }
}
