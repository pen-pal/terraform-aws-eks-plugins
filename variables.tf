variable "cluster_id" {
  description = "ID of the  EKS Cluster where the addons are to be provisioned"
  type        = string
  default     = null
}

variable "config" {
  description = "Standard parameters"
  type = object({
    product     = string
    environment = string
    service     = string
  })
}

variable "oidc_issuer" {
  description = "oidc_issuer"
  type        = string
  default     = ""
}

variable "create_autoscaler" {
  description = "either to create and deploy eks cluster autoscaler resources"
  type        = bool
  default     = false
}

variable "create_metricserver" {
  description = "either to create and deploy eks metric server resources"
  type        = bool
  default     = false
}

variable "create_nvidiadeviceplugin" {
  description = "either to create and deploy eks nvidia device plugin for gpu resources"
  type        = bool
  default     = false
}

variable "create_albcontroller" {
  description = "either to create and deploy eks load balancer controller resources"
  type        = bool
  default     = false
}

variable "create_externalsecretsmanager" {
  description = "either to create and deploy external secrets manager resources"
  type        = bool
  default     = false
}
