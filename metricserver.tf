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
