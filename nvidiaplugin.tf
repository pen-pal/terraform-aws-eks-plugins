resource "helm_release" "nvidiadeviceplugin" {
  count = var.create_nvidiadeviceplugin ? 1 : 0

  name       = "nvidiadeviceplugin"
  repository = "https://nvidia.github.io/k8s-device-plugin"
  chart      = "nvidia-device-plugin"
  version    = "0.11.0"

  set {
    name  = "compatWithCPUManager"
    value = "true"
  }

  set {
    name  = "migStrategy"
    value = "mixed"
  }
}
