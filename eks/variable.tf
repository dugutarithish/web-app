
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "my-eks-cluster"
}

variable "cluster_version" {
  description = "EKS Kubernetes cluster version"
  type        = string
  default     = "1.37"
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster and node groups"
  type        = list(string)
}

variable "node_groups" {
  description = "EKS node group configuration"

  type = map(object({
    instance_types = list(string)
    capacity_type  = string

    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })
  }))

  default = {
    general = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      scaling_config = {
        desired_size = 2
        max_size     = 4
        min_size     = 1
      }
    }
  }
}
