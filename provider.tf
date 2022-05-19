### configure kubernetes provider
provider "kubernetes" {
  host                   = element(concat(data.aws_eks_cluster.cluster.*.endpoint, [""]), 0)
  cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.cluster.*.certificate_authority.0.data, [""]), 0))
  token                  = element(concat(data.aws_eks_cluster_auth.cluster.*.token, [""]), 0)
}

### configure helm provider
provider "helm" {
  kubernetes {
  host                   = element(concat(data.aws_eks_cluster.cluster.*.endpoint, [""]), 0)
  cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.cluster.*.certificate_authority.0.data, [""]), 0))
  token                  = element(concat(data.aws_eks_cluster_auth.cluster.*.token, [""]), 0)
  }  
}
