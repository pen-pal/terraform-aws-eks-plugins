data "aws_iam_policy_document" "read_store" {
  count = var.create_externalsecretsmanager ? 1 : 0

  statement {
    sid = "ReadSecretsStore"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParametersByPath"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.config.environment}/*"
    ]
  }
}

# iam role for external_secrets_manager
resource "aws_iam_policy" "read_store_policy" {
  count = var.create_externalsecretsmanager ? 1 : 0

  name   = "${local.name_prefix}_read_store_policy"
  policy = data.aws_iam_policy_document.read_store[0].json
}

# using community module instead, much cleaner
module "iam_iam-assumable-role-with-oidc" {
  count = var.create_externalsecretsmanager ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.2.0"

  create_role = true
  role_name   = "${local.name_prefix}-role"

  # provider url is cleaned up in module
  provider_urls = [local.eks.oidc_issuer]

  role_policy_arns = [
    aws_iam_policy.read_store_policy[0].arn
  ]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.externalsecrets.namespace}:${local.externalsecrets.serviceaccount}"]

}

# create service accont and annotate with iam role
resource "kubernetes_service_account" "externalsecrets_serviceaccount" {
  count = var.create_externalsecretsmanager ? 1 : 0

  metadata {
    name      = local.externalsecrets.serviceaccount
    namespace = local.externalsecrets.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_iam-assumable-role-with-oidc[0].iam_role_arn
    }
  }
  automount_service_account_token = true
  depends_on                      = [module.iam_iam-assumable-role-with-oidc]
}

# src: https://github.com/external-secrets/kubernetes-external-secrets#install-with-helm
# helm repo add external-secrets https://external-secrets.github.io/kubernetes-external-secrets/
# helm install [RELEASE_NAME] external-secrets/kubernetes-external-secrets
resource "helm_release" "external_secrets_manager" {
  count = var.create_externalsecretsmanager ? 1 : 0

  name       = "${local.prefix}-externalsecrets"
  repository = "https://external-secrets.github.io/kubernetes-external-secrets"
  chart      = "kubernetes-external-secrets"
  version    = "8.2.2"
  namespace  = local.externalsecrets.namespace

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = local.externalsecrets.serviceaccount
  }
  set {
    name  = "env.AWS_REGION"
    value = data.aws_region.current.name
  }

  depends_on = [kubernetes_service_account.externalsecrets_serviceaccount]
}
