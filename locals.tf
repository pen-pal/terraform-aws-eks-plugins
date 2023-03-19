locals {
  prefix      = "${var.config.product}-${var.config.environment}-${var.config.service}"
  name_prefix = "${local.prefix}-eks"

  componet = "eks"
  config   = var.config

  eks = {
    cluster_id       = var.cluster_id
    oidc_issuer      = var.oidc_issuer
    oidc_issuer_arn  = var.oidc_issuer_arn
    addons_namespace = "kube-system"
  }

  clusterautoscaler = {
    namespace = local.eks.addons_namespace
    name      = "cluster-autoscaler"
  }

  external-secrets = {
    name      = "external-secrets"
    namespace = "${var.external_secret_namespace}"
  }

  alb = {
    name      = "aws-load-balancer-controller"
    namespace = local.eks.addons_namespace
  }

  metric-server = {
    namespace      = "kube-system"
    serviceaccount = "metrics-server"
  }

  aws = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
  }

  karpenter = {
    namespace = local.eks.addons_namespace
    name      = "karpenter"
  }


  node-termination-handler = {
    namespace = local.eks.addons_namespace
    name      = "node-termination-handler"

    event_rules = flatten([
      length(var.autoscaling_group_names) > 0 ?
      [{
        name          = substr("NTHASGTermRule-${var.cluster_id}", 0, 63),
        event_pattern = <<EOF
{"source":["aws.autoscaling"],"detail-type":["EC2 Instance-terminate Lifecycle Action"]}
EOF
      }] : [],
      {
        name          = substr("NTHSpotTermRule-${var.cluster_id}", 0, 63),
        event_pattern = <<EOF
{"source": ["aws.ec2"],"detail-type": ["EC2 Spot Instance Interruption Warning"]}
EOF
      },
      {
        name          = substr("NTHRebalanceRule-${var.cluster_id}", 0, 63),
        event_pattern = <<EOF
{"source": ["aws.ec2"],"detail-type": ["EC2 Instance Rebalance Recommendation"]}
EOF
      },
      {
        name          = substr("NTHInstanceStateChangeRule-${var.cluster_id}", 0, 63),
        event_pattern = <<EOF
{"source": ["aws.ec2"],"detail-type": ["EC2 Instance State-change Notification"]}
EOF
      },
      {
        name          = substr("NTHScheduledChangeRule-${var.cluster_id}", 0, 63),
        event_pattern = <<EOF
{"source": ["aws.health"],"detail-type": ["AWS Health Event"]}
EOF
      }
    ])
  }

  external-dns = {
    namespace = local.eks.addons_namespace
    name      = "external-dns"
  }

  kube-cost = {
    namespace = local.eks.addons_namespace
    name      = "ingress-nginx"
  }

  ingress-nginx = {
    namespace = local.eks.addons_namespace
    name      = "ingress-nginx"
  }

  reloader = {
    namespace = var.config.environment
    name      = "reloader"
  }

}
