#!/bin/bash
set -e

# Constants
NAMESPACE="CloudWebApp/Metrics"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Health check
HEALTH_STATUS=$(curl -s http://localhost:5000/health | grep -q "OK" && echo 100 || echo 0)

# CPU usage (%)
CPU_UTIL=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')

# Memory usage (%)
MEMORY_UTIL=$(free | awk '/Mem/ {printf("%.2f", $3/$2 * 100.0)}')

# Push metrics to CloudWatch
aws cloudwatch put-metric-data --metric-name CPUUtilization \
    --dimensions InstanceId=$INSTANCE_ID \
    --namespace "$NAMESPACE" \
    --value "$CPU_UTIL" \
    --unit Percent

aws cloudwatch put-metric-data --metric-name MemoryUtilization \
    --dimensions InstanceId=$INSTANCE_ID \
    --namespace "$NAMESPACE" \
    --value "$MEMORY_UTIL" \
    --unit Percent

aws cloudwatch put-metric-data --metric-name HealthStatus \
    --dimensions InstanceId=$INSTANCE_ID \
    --namespace "$NAMESPACE" \
    --value "$HEALTH_STATUS" \
    --unit Percent

echo "✅ Metrics pushed to CloudWatch successfully."
