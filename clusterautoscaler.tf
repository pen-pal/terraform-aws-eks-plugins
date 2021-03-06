data "aws_iam_policy_document" "cluster_autoscaler" {
  count = var.create_autoscaler ? 1 : 0

  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${local.eks.cluster_id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.create_autoscaler ? 1 : 0

  name_prefix = local.name_prefix
  description = "EKS cluster-autoscaler policy for cluster ${local.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler[0].json
}

module "iam-assumable-role-with-oidc-ca" {
  count = var.create_autoscaler ? 1 : 0

  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.3.0"
  create_role                   = true
  role_name                     = local.name_prefix
  provider_url                  = replace(local.eks.oidc_issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.cluster_autoscaler[0].arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.clusterautoscaler.namespace}:${local.clusterautoscaler.serviceaccount}"]
}

# create service accont and annotate with iam role
resource "kubernetes_service_account" "clusterautoscaler_serviceaccount" {
  count = var.create_autoscaler ? 1 : 0

  metadata {
    name      = local.clusterautoscaler.serviceaccount
    namespace = local.clusterautoscaler.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam-assumable-role-with-oidc-ca[0].iam_role_arn
    }
  }
  automount_service_account_token = true
  depends_on                      = [module.iam-assumable-role-with-oidc-ca]
}

# apply helm chart  maintained by clusterautoscaler team
resource "helm_release" "clusterautoscaler" {
  count = var.create_autoscaler ? 1 : 0

  name       = "cluster-controller"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.10.7"
  namespace  = local.clusterautoscaler.namespace

  set {
    name  = "rbac.serviceAccount.create"
    value = "false"
  }
  set {
    name  = "rbac.serviceAccount.name"
    value = local.clusterautoscaler.serviceaccount
  }
  set {
    name  = "autoDiscovery.clusterName"
    value = local.eks.cluster_id
  }
  set {
    name  = "autoDiscovery.enabled"
    value = true
  }
  set {
    name  = "awsRegion"
    value = local.aws.region
  }
  depends_on = [kubernetes_service_account.clusterautoscaler_serviceaccount]
}
