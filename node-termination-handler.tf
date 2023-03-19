data "aws_iam_policy_document" "aws_node_termination_handler_queue_policy_document" {
  count = var.create-node-termination-handler ? 1 : 0
  statement {
    actions = [
      "sqs:SendMessage"
    ]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sqs.amazonaws.com"
      ]
    }
    resources = [
      aws_sqs_queue.aws_node_termination_handler_queue[0].arn
    ]
  }
}

data "aws_iam_policy_document" "irsa_policy" {
  count = var.create-node-termination-handler ? 1 : 0
  statement {
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
    ]
    resources = ["*"]
  }
}

resource "aws_autoscaling_lifecycle_hook" "aws_node_termination_handler_hook" {
  count = var.create-node-termination-handler ? length(var.autoscaling_group_names) : 0

  name                   = "aws_node_termination_handler_hook"
  autoscaling_group_name = var.autoscaling_group_names[count.index]
  default_result         = "CONTINUE"
  heartbeat_timeout      = 300
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}

resource "aws_autoscaling_group_tag" "aws_node_termination_handler_tag" {
  count = var.create-node-termination-handler ? length(var.autoscaling_group_names) : 0

  autoscaling_group_name = var.autoscaling_group_names[count.index]

  tag {
    key   = "aws-node-termination-handler/managed"
    value = "true"

    propagate_at_launch = true
  }
}

#tfsec:ignore:aws-sqs-enable-queue-encryption
resource "aws_sqs_queue" "aws_node_termination_handler_queue" {
  count                     = var.create-node-termination-handler ? 1 : 0
  name_prefix               = "aws_node_termination_handler"
  message_retention_seconds = "300"
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue_policy" "aws_node_termination_handler_queue_policy" {
  count     = var.create-node-termination-handler ? 1 : 0
  queue_url = aws_sqs_queue.aws_node_termination_handler_queue[0].id
  policy    = data.aws_iam_policy_document.aws_node_termination_handler_queue_policy_document[0].json
}

resource "aws_cloudwatch_event_rule" "aws_node_termination_handler_rule" {
  count = var.create-node-termination-handler ? length(local.node-termination-handler.event_rules) : 0

  name          = local.node-termination-handler.event_rules[count.index].name
  event_pattern = local.node-termination-handler.event_rules[count.index].event_pattern
}

resource "aws_cloudwatch_event_target" "aws_node_termination_handler_rule_target" {
  count = var.create-node-termination-handler ? length(aws_cloudwatch_event_rule.aws_node_termination_handler_rule.*.arn) : 0

  rule = aws_cloudwatch_event_rule.aws_node_termination_handler_rule[count.index].id
  arn  = aws_sqs_queue.aws_node_termination_handler_queue[0].arn
}

resource "aws_iam_policy" "aws_node_termination_handler_irsa" {
  count       = var.create-node-termination-handler ? 1 : 0
  description = "IAM role policy for AWS Node Termination Handler"
  name        = "${var.cluster_id}-aws-nth-irsa"
  policy      = data.aws_iam_policy_document.irsa_policy[0].json
}

## using community module instead, much cleaner
#module "iam_assumable_role_with_oidc_node_termination_handler" {
#  count = var.create-node-termination-handler ? 1 : 0
#
#  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#  version = "4.2.0"
#
#  create_role = true
#  role_name   = "${local.component}-${local.node-termination-handler.name}-role"
#
#  # provider url is cleaned up in module
#  provider_urls = [local.eks.oidc_issuer]
#
#  role_policy_arns = [
#    aws_iam_policy.aws_node_termination_handler_irsa[0].arn
#  ]
#  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.node-termination-handler.namespace}:${local.node-termination-handler.name}-sa"]
#
#}
#

module "node_termination_handler_irsa_role" {
  count = var.create-node-termination-handler ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.5.5"

  role_name                              = "node-termination-handler"
  attach_node_termination_handler_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_issuer_arn
      namespace_service_accounts = ["kube-system:${local.node-termination-handler.name}-sa"]
    }
  }

  tags = {
    Name           = "node-termination-handler"
    ServiceAccount = "node-termination-handler-sa"
  }
}

# create service accont and annotate with iam role
resource "kubernetes_service_account" "node-termination-handler-serviceaccount" {
  count = var.create-node-termination-handler ? 1 : 0

  metadata {
    name      = "${local.node-termination-handler.name}-sa"
    namespace = local.node-termination-handler.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = module.node_termination_handler_irsa_role[0].iam_role_arn
    }
  }
  automount_service_account_token = true
  depends_on                      = [module.node_termination_handler_irsa_role]
}

resource "helm_release" "node-termination-handler" {
  count = var.create-node-termination-handler ? 1 : 0

  name            = "aws-node-termination-handler"
  repository      = "https://aws.github.io/eks-charts"
  chart           = "aws-node-termination-handler"
  version         = "0.19.3"
  namespace       = local.node-termination-handler.namespace
  description     = "Helm chart for the AWS Node Termination Handler"
  cleanup_on_fail = true

  set {
    name  = "enableSqsTerminationDraining"
    value = "true"
    type  = "auto"
  }
  set {
    name  = "queueURL"
    value = aws_sqs_queue.aws_node_termination_handler_queue[0].id
    type  = "string"
  }
  set {
    name  = "webhookURL"
    value = "https://chat.googleapis.com/v1/spaces/AAAA789FxMU/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=EgW7xTlXfvM-xPkFD9OmhI8vRkhHhu18ajCOb0AaoHg%3D"
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
    type  = "auto"
  }
  set {
    name  = "serviceAccount.name"
    value = "${local.node-termination-handler.name}-sa"
    type  = "string"
  }
  set {
    name  = "enablePrometheusServer"
    value = "true"
    type  = "auto"
  }
  set {
    name  = "checkASGTagBeforeDraining"
    value = length(var.autoscaling_group_names) == 0 ? false : true
    type  = "auto"
  }
}



