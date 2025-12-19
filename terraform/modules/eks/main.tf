variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "node_subnet_ids" {
  description = "Subnets for worker nodes (Single AZ)"
  type        = list(string)
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id                   = var.vpc_id
  subnet_ids               = var.node_subnet_ids    # Worker nodes in Single AZ
  control_plane_subnet_ids = var.private_subnet_ids # Control plane endpoints in Multi-AZ

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    # CPU Node Group for Control Plane Components (Karpenter, Argo, etc)
    # On-Demand: 2x t3.large
    system = {
      name           = "system-nodes"
      instance_types = ["t3.xlarge"]
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      capacity_type  = "ON_DEMAND"

      labels = {
        "role" = "system"
      }
    }

  }

  #  force_irsa = true
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

