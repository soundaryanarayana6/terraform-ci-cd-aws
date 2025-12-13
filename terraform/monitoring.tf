
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.environment}-app"
  retention_in_days = 7

  tags = {
    Name = "${var.environment}-app-logs"
  }
}


resource "aws_cloudwatch_log_group" "alb_access_logs" {
  name              = "/aws/alb/${var.environment}-alb/access"
  retention_in_days = 7

  tags = {
    Name = "${var.environment}-alb-access-logs"
  }
}

# System logs (for future use - VPC Flow Logs, etc.)
resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/aws/${var.environment}/system"
  retention_in_days = 7

  tags = {
    Name = "${var.environment}-system-logs"
  }
}

# Dashboard 1: Infrastructure Metrics (CPU, Memory, Disk)
resource "aws_cloudwatch_dashboard" "infrastructure" {
  dashboard_name = "${var.environment}-infrastructure-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ECS CPU Utilization
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.app.name, { stat = "Average" }],
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.app.name, { stat = "Maximum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Service CPU Utilization (%)"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      # ECS Memory Utilization
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.app.name, { stat = "Average" }],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.app.name, { stat = "Maximum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Service Memory Utilization (%)"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      # RDS CPU Utilization
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.postgres.identifier, { stat = "Average" }],
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.postgres.identifier, { stat = "Maximum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS CPU Utilization (%)"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      # RDS Memory Utilization
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", aws_db_instance.postgres.identifier, { stat = "Average", label = "Freeable Memory" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.postgres.identifier, { stat = "Average", label = "Free Storage" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Memory & Storage"
        }
      },
      # RDS Disk I/O
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", aws_db_instance.postgres.identifier, { stat = "Sum", label = "Read IOPS" }],
            ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", aws_db_instance.postgres.identifier, { stat = "Sum", label = "Write IOPS" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "RDS Disk I/O Operations"
        }
      },
      # RDS Database Connections
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.postgres.identifier]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Database Connections"
        }
      }
    ]
  })
}


resource "aws_cloudwatch_dashboard" "application" {
  dashboard_name = "${var.environment}-application-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix, { stat = "Sum", label = "Total Requests" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Request Count"
        }
      },
      # Request Rate
      {
        type   = "metric"
        x      = 6
        y      = 0
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix, { stat = "Rate", label = "Request Rate (req/sec)" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Request Rate (req/sec)"
        }
      },
      # Target Error Rates
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", aws_lb.main.arn_suffix, { stat = "Sum", label = "4XX Errors" }],
            ["...", "HTTPCode_Target_5XX_Count", ".", ".", { stat = "Sum", label = "5XX Errors" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Target Error Rates"
        }
      },
      # ALB Error Rates
      {
        type   = "metric"
        x      = 18
        y      = 0
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", aws_lb.main.arn_suffix, { stat = "Sum", label = "ALB 4XX" }],
            ["...", "HTTPCode_ELB_5XX_Count", ".", ".", { stat = "Sum", label = "ALB 5XX" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Error Rates"
        }
      },
      # Latency Metrics
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { stat = "Average", label = "Avg Response Time" }],
            ["...", ".", ".", ".", { stat = "p50", label = "p50" }],
            ["...", ".", ".", ".", { stat = "p95", label = "p95" }],
            ["...", ".", ".", ".", { stat = "p99", label = "p99" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Application Latency (ms)"
        }
      },
      # Target Health (using LoadBalancer dimension)
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", aws_lb.main.arn_suffix, { stat = "Average", label = "Healthy Targets" }],
            ["...", "UnHealthyHostCount", ".", ".", { stat = "Average", label = "Unhealthy Targets" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Target Health Status"
        }
      },
      # Request Count by Status Code
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", aws_lb.main.arn_suffix, { stat = "Sum", label = "2XX" }],
            ["...", "HTTPCode_Target_3XX_Count", ".", ".", { stat = "Sum", label = "3XX" }],
            ["...", "HTTPCode_Target_4XX_Count", ".", ".", { stat = "Sum", label = "4XX" }],
            ["...", "HTTPCode_Target_5XX_Count", ".", ".", { stat = "Sum", label = "5XX" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Request Count by Status Code"
        }
      },
      # Active Connection Count
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", aws_lb.main.arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Active Connections"
        }
      }
    ]
  })
}


resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "${var.environment}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = []

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  tags = {
    Name = "${var.environment}-ecs-high-cpu-alarm"
  }
}


resource "aws_cloudwatch_metric_alarm" "ecs_high_memory" {
  alarm_name          = "${var.environment}-ecs-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS memory utilization"
  alarm_actions       = []

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  tags = {
    Name = "${var.environment}-ecs-high-memory-alarm"
  }
}

# High Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "alb_high_error_rate" {
  alarm_name          = "${var.environment}-alb-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors ALB 5XX error rate"
  alarm_actions       = []

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name = "${var.environment}-alb-high-error-rate-alarm"
  }
}

# High Latency Alarm
resource "aws_cloudwatch_metric_alarm" "alb_high_latency" {
  alarm_name          = "${var.environment}-alb-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 1000
  alarm_description   = "This metric monitors ALB response time"
  alarm_actions       = []

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name = "${var.environment}-alb-high-latency-alarm"
  }
}

# RDS High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }

  tags = {
    Name = "${var.environment}-rds-high-cpu-alarm"
  }
}
