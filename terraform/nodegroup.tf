resource "aws_eks_node_group" "node_group" {
  cluster_name    = "my-cluster"
  node_group_name = "demo-node-group"
  node_role_arn   = "arn:aws:iam::123456789012:role/EKSNodeInstanceRole"
  subnet_ids      = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
}
