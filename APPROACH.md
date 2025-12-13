# Approach Documentation

### 1. **Infrastructure Strategy (Terraform)**
- **Cloud Provider**: AWS.
- **Core Service**: **Amazon ECS (Fargate)**.
- **Reasoning**: Chosen over EC2/ASG for simplified management (serverless) and over EKS for significant cost savings (no control plane fee).
- **Networking**: VPC with public/private subnets. ALB handles ingress traffic.
- **Database**: RDS PostgreSQL. was chosen for managed database reliability. kept off public access for security.

## Part 2: Deployment Automation
**Tool**: GitHub Actions

I selected GitHub Actions for its seamless integration with the repository.
- **CI**: Focused on speed and security. Included `Trivy` for fs/container scanning to shift security left.
- **CD**: Implemented a "Build Once, Deploy Many" pattern (simulated). The critical logical step is the **Manual Approval** gate using GitHub Environments for Production, preventing accidental deployments.

## Part 3: Monitoring and Logging
**Tool**: AWS CloudWatch

Chosen for native integration with AWS resources.
- **Dashboards**: Created a comprehensive view combining Infrastructure (CPU) and Application (ALB Latency) metrics.
- **Logging**: Centralized Log Group for application logs ensures that logs are persisted even if instances are terminated by ASG.

## Part 4: Documentation
Focus was on clarity and recoverability. The README provides a specific "How-to" guide to ensure anyone can pick up the project and run it.
