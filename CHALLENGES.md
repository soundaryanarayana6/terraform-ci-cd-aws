# Challenges & Resolutions

## Challenge 1: Handling Secrets in Terraform
**Issue**: Passing database passwords securely.
**Resolution**: Defined `variable "db_password" { sensitive = true }` in Terraform and configured GitHub Actions to pass it via `-var="db_password=${{ secrets.DB_PASSWORD }}"` during the `terraform apply` step. This ensures the password is never stored in git.

## Challenge 2: Cost vs Availability
**Issue**: Running a NAT Gateway per Availability Zone is expensive (~$30/month each).
**Resolution**: Configured a single NAT Gateway for the workspace. While this reduces HA (if that one AZ goes down), it is a pragmatic trade-off for a cost-optimized dev/assessment environment.

## Challenge 3: CI/CD "Dry Run"
**Issue**: Without a real AWS account integrated with GitHub Secrets during development, the pipeline fails.
**Resolution**: Added comments/placeholders in the workflow files to show *exactly* where `terraform apply` would run, allowing the logic to be reviewed without requiring active credentials during the coding phase.

## Challenge 4: Dependency Management
**Issue**: Ensuring Security Groups allow traffic correctly before instances launch.
**Resolution**: Used explicit `depends_on` or implicit references (passing IDs) to ensure proper graph execution order in Terraform.

## Challenge 5: EKS Networking
**Issue**: Load Balancers were not being created by the Kubernetes Service.
**Resolution**: Added the required tags `kubernetes.io/cluster/<cluster-name> = shared` to the VPC subnets so that the AWS Cloud Controller Manager could discover them.

## Challenge 6: Free Tier vs EKS
**Issue**: User requested "Only Free Tier" but also "Use EKS". EKS Control Plane costs ~$73/month and is not Free Tier.
**Resolution**: Switched from EKS to **Amazon ECS (Fargate)**. Fargate has no fixed cluster cost, charging only for resources used by running tasks. This is much closer to the "Free Tier" goal while maintaining a containerized architecture. We also removed NAT Gateways and used Public Subnets for ECS tasks to avoid NAT costs.
