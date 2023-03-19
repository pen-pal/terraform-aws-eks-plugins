############################################
# Metric Server Helm
############################################
resource "helm_release" "metricsserver" {
  count = var.create-metric-server ? 1 : 0

  name       = "metricsserveer"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.8.3"
  namespace  = local.metric-server.namespace

  set {
    name  = "metrics.enabled"
    value = "true"
  }

}
