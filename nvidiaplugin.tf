resource "helm_release" "nvidiadeviceplugin" {
  count = creat_nvidiadeviceplugin ? 1 : 0

  name       = "nvidiadeviceplugin"
  repository = "https://github.com/NVIDIA/k8s-device-plugin"
  chart      = "vdp/nvidia-device-plugin"
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
