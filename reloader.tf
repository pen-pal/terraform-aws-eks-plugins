
resource "helm_release" "reloader" {
  count = var.create-reloader ? 1 : 0

  name            = "reloader"
  repository      = "https://stakater.github.io/stakater-charts"
  chart           = "reloader"
  version         = "v0.0.124"
  namespace       = local.reloader.namespace
  description     = "Reloader Helm Chart deployment configuration"
  cleanup_on_fail = true

  set {
    name  = "reloader.watchGlobally"
    value = "false"
  }
}
