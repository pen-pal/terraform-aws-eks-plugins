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

variable "oidc_issuer_arn" {
  description = "oidc_issuer_arn"
  type        = string
  default     = ""
}

variable "create-cluster-autoscaler" {
  description = "either to create and deploy eks cluster cluster-autoscaler resources"
  type        = bool
  default     = false
}
#
variable "create-metric-server" {
  description = "either to create and deploy eks metric server resources"
  type        = bool
  default     = false
}

#variable "create-nvidiadeviceplugin" {
#  description = "either to create and deploy eks nvidia device plugin for gpu resources"
#  type        = bool
#  default     = false
#}
#
variable "create-albcontroller" {
  description = "either to create and deploy eks load balancer controller resources"
  type        = bool
  default     = false
}

variable "create-external-secrets" {
  description = "either to create and deploy external secrets manager resources"
  type        = bool
  default     = false
}

variable "cluster_endpoint" {
  description = "Kubernetes Cluster endpoint"
  type        = string
  default     = ""
}


variable "cluster_certificate_authority_data" {
  description = "Kubernetes Cluster Certificate"
  type        = string
  default     = ""
}

variable "external_secret_namespace" {
  type    = string
  default = "production"
}

variable "create-external-dns" {
  description = "either to create and deploy external secrets manager resources"
  type        = bool
  default     = false
}

variable "create-reloader" {
  description = "either to create and deploy external secrets manager resources"
  type        = bool
  default     = false
}

variable "create-node-termination-handler" {
  description = "either to create and deploy external secrets manager resources"
  type        = bool
  default     = false
}

variable "create-ingress-nginx" {
  description = "either to create and deploy external secrets manager resources"
  type        = bool
  default     = false
}

variable "create-karpenter" {
  description = "either to create and deploy external secrets manager resources"
  type        = bool
  default     = false
}

#variable "eks_managed_node_groups_arn" {
#  description = "arn of EKS managed node groups created"
#  type        = string
#  default     = ""
#}
#
#variable "eks_managed_node_groups_role" {
#  description = "role of EKS managed node groups created"
#  type        = string
#  default     = ""
#}

variable "autoscaling_group_names" {
  description = "EKS Node Group ASG names"
  type        = list(string)
}


variable "domain_name" {
  description = "[Deprecated - use `route53_zone_arns`] Domain name of the Route53 hosted zone to use with External DNS."
  type        = string
}

variable "private_zone" {
  description = "[Deprecated - use `route53_zone_arns`] Determines if referenced Route53 hosted zone is private."
  type        = bool
  default     = false
}

variable "route53_zone_arns" {
  description = "List of Route53 zones ARNs which external-dns will have access to create/manage records"
  type        = list(string)
  default     = []
}

