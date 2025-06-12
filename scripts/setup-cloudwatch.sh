#!/bin/bash
set -e

echo "🔧 Setting up CloudWatch monitoring and SNS alerts..."

# Variables
TOPIC_NAME="CloudWebAppAlerts"
ALARM_PREFIX="CloudWebApp"
EMAIL="Lygashiku@gmail.com"  # Replace with your email

# Create SNS Topic
echo "📧 Creating SNS topic for alerts..."
TOPIC_ARN=$(aws sns create-topic --name $TOPIC_NAME --query 'TopicArn' --output text)
echo "Topic ARN: $TOPIC_ARN"

# Subscribe email to SNS topic
echo "📩 Subscribing email to SNS topic..."
aws sns subscribe \
    --topic-arn $TOPIC_ARN \
    --protocol email \
    --notification-endpoint $EMAIL

echo "⚠️  Please check your email and confirm the SNS subscription!"

# Create CloudWatch Alarms
echo "🚨 Creating CloudWatch alarms..."

# CPU Alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "${ALARM_PREFIX}-HighCPU" \
    --alarm-description "Alarm when CPU exceeds 70%" \
    --metric-name CPUUtilization \
    --namespace CloudWebApp/Metrics \
    --statistic Average \
    --period 300 \
    --threshold 70 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions $TOPIC_ARN \
    --ok-actions $TOPIC_ARN

# Memory Alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "${ALARM_PREFIX}-HighMemory" \
    --alarm-description "Alarm when Memory exceeds 80%" \
    --metric-name MemoryUtilization \
    --namespace CloudWebApp/Metrics \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions $TOPIC_ARN \
    --ok-actions $TOPIC_ARN

# Health Status Alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "${ALARM_PREFIX}-ApplicationDown" \
    --alarm-description "Alarm when application is unhealthy" \
    --metric-name HealthStatus \
    --namespace CloudWebApp/Metrics \
    --statistic Average \
    --period 300 \
    --threshold 50 \
    --comparison-operator LessThanThreshold \
    --evaluation-periods 1 \
    --alarm-actions $TOPIC_ARN \
    --ok-actions $TOPIC_ARN

echo "✅ CloudWatch setup complete!"
echo "📊 View your metrics at: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#metricsV2:graph=~();namespace=CloudWebApp/Metrics"