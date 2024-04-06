# terraform-backend-state-learning
# AKIAQRA7PEMMVTZGG2GL

terraform {
  backend "s3" {
    bucket = "mybucket"
    key    = "path/to/my/key"
    region = "us-east-2"
  }
}

resource "aws_default_vpc" "default" {

}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "devops-learning-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "devops-learning-cluster"
  cluster_version = "1.29"
  subnet_ids         = ["subnet-2f427347", "subnet-ac7a15d6", "subnet-eb63b4a7"]
  vpc_id          = aws_default_vpc.default.id

  cluster_endpoint_public_access  = true

# EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t2.small", "t2.medium"]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t2.medium"]
    }
  }
}

data "aws_eks_cluster" "cluster" {
 name = "devops-learning-cluster" #module.in28minutes-cluster.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = "devops-learning-cluster" #module.in28minutes-cluster.cluster_name
}

resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "fabric8-rbac"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }
}

# Needed to set the default region
provider "aws" {
  region  = "us-east-2"
}