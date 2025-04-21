provider "aws" {
  region = "us-west-2"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-cluster"
  cluster_version = "1.27"
  subnets         = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
  vpc_id          = "vpc-zzzzzzzz"
}
