module "external_dns_irsa_role" {
  count = var.create-external-dns ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "v5.5.5"

  role_name                     = "external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${var.domain_name}"]

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_issuer_arn
      namespace_service_accounts = ["kube-system:${local.external-dns.name}-sa"]
    }
  }

  tags = {
    Name           = "external-dns"
    ServiceAccount = "external-dns-sa"
  }
}

## create service accont and annotate with iam role
resource "kubernetes_service_account" "external-dns-serviceaccount" {
  count = var.create-external-dns ? 1 : 0

  metadata {
    name      = "${local.external-dns.name}-sa"
    namespace = local.external-dns.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_dns_irsa_role[0].iam_role_arn
    }
  }
  automount_service_account_token = true
  depends_on                      = [module.external_dns_irsa_role]
}

resource "helm_release" "external-dns" {
  count = var.create-external-dns ? 1 : 0

  name            = "external-dns"
  repository      = "https://charts.bitnami.com/bitnami"
  chart           = "external-dns"
  version         = "6.11.2"
  namespace       = local.external-dns.namespace
  description     = "Helm chart for the External DNS"
  cleanup_on_fail = true

  set {
    name  = "aws.region"
    value = local.aws.region
    type  = "string"
  }
  set {
    name  = "serviceAccount.name"
    value = "${local.external-dns.name}-sa"
    type  = "string"
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
    type  = "auto"
  }
}
#
#
#
