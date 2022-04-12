resource "aws_iam_policy" "service_account_policy" {
  count = var.create_albcontroller ? 1 : 0

  name        = "${local.name_prefix}-policy"
  description = "Policy to manage ALB via ALB Ingress Controller"
  policy      = file("${path.module}/files/iam_policy.json")
}

# create iam role for alb to use
data "aws_iam_policy_document" "alb_web_identity_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.alb.namespace}:${local.alb.serviceaccount}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [local.oidc_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "alb_web_identity_role" {
  count = var.create_albcontroller ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.alb_web_identity_assume_role_policy.json
  name               = "${local.prefix}-albc"
}

# attach policy
resource "aws_iam_role_policy_attachment" "attached_policy" {
  count = var.create_albcontroller ? 1 : 0

  role       = aws_iam_role.alb_web_identity_role.name
  policy_arn = aws_iam_policy.service_account_policy.arn
}

# create service accont and annotate with iam role
resource "kubernetes_service_account" "alb-serviceaccount" {
  count = var.create_albcontroller ? 1 : 0

  metadata {
    name      = local.alb.serviceaccount
    namespace = local.alb.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_web_identity_role.arn
    }
  }
  automount_service_account_token = true
}

## install alb controller with helm chart
# helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=<cluster-name> --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
resource "helm_release" "alb-controller" {
  count = var.create_albcontroller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  #chart     = "https://aws.github.io/eks-charts/aws-load-balancer-controller-1.2.1.tgz"
  chart     = "eks/aws-load-balancer-controller"
  version   = "2.4.1"
  namespace = local.alb.namespace

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = local.alb.serviceaccount
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_id
    type  = "string"
  }
  depends_on = [kubernetes_service_account.alb-serviceaccount]
}

#################################################################################
## enable access logs
# doc: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html?icmpid=docs_elbv2_console
#################################################################################
resource "aws_s3_bucket" "elb_logs" {
  count = var.create_albcontroller ? 1 : 0

  bucket        = local.name_prefix
  acl           = "private"
  force_destroy = true
  policy        = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_elb_service_account.main.arn}"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.name_prefix}/${var.config.environment}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.name_prefix}/${var.config.environment}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${local.name_prefix}"
    }
  ]
}
POLICY
}
