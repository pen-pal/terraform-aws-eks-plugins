module "external_secrets_irsa_role" {
  count = var.create-external-secrets ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> v5.11.1"

  role_name                      = "external-secrets"
  attach_external_secrets_policy = true
  external_secrets_ssm_parameter_arns = [
    "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.external-secrets.namespace}/*"
  ]

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_issuer_arn
      namespace_service_accounts = ["${local.external-secrets.namespace}:${local.external-secrets.name}-sa"]
    }
  }

  tags = {
    Name           = "external-secrets"
    ServiceAccount = "external-secrets-sa"
  }
}

## create service accont and annotate with iam role
resource "kubernetes_service_account" "external-secrets-serviceaccount" {
  count = var.create-external-secrets ? 1 : 0

  metadata {
    name      = "${local.external-secrets.name}-sa"
    namespace = local.external-secrets.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_secrets_irsa_role[0].iam_role_arn
    }
  }
  automount_service_account_token = true
  depends_on                      = [module.external_secrets_irsa_role]
}

#
resource "helm_release" "external-secrets-oprator" {
  count = var.create-external-secrets ? 1 : 0

  name            = "external-secrets"
  chart           = "external-secrets"
  repository      = "https://charts.external-secrets.io"
  version         = "0.7.2"
  namespace       = local.external-secrets.namespace
  description     = "The External Secrets Operator Helm chart default configuration"
  cleanup_on_fail = true

  set {
    name  = "serviceAccount.create"
    value = "false"
    type  = "auto"
  }
  set {
    name  = "serviceAccount.name"
    value = "${local.external-secrets.name}-sa"
    type  = "string"
  }
  set {
    name  = "env.AWS_REGION"
    value = data.aws_region.current.name
    type  = "string"
  }
  #set {
  #  name  = "serviceMonitor.enabled"
  #  value = "true"
  #  type  = "auto"
  #}
  set {
    name  = "webhook.serviceAccount.name"
    value = "${local.external-secrets.name}-sa"
    type  = "string"
  }
  set {
    name  = "webhook.serviceAccount.create"
    value = "false"
    type  = "auto"
  }
  set {
    name  = "certController.serviceAccount.name"
    value = "${local.external-secrets.name}-sa"
    type  = "string"
  }
  set {
    name  = "certController.serviceAccount.create"
    value = "false"
    type  = "auto"
  }
}
