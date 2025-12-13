output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS cluster endpoint"
}

output "cluster_version" {
  value       = aws_eks_cluster.main.version
  description = "EKS cluster version"
}

output "cluster_arn" {
  value       = aws_eks_cluster.main.arn
  description = "EKS cluster ARN"
}

output "node_group_id" {
  value       = aws_eks_node_group.main.id
  description = "EKS node group ID"
}

output "eks_node_sg_id" {
  value       = aws_security_group.eks_node_sg.id
  description = "Security group ID for EKS nodes"
}

output "cluster_security_group_id" {
  value       = aws_security_group.eks_cluster_sg.id
  description = "Security group ID for EKS cluster"
}
