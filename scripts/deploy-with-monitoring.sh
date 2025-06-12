#!/bin/bash
set -e

echo "🚀 Deploying Cloud Web App with Full Monitoring..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Build Docker image
echo "🔨 Building Docker image..."
docker build -t cloud-webapp .

# Stop existing container
echo "🛑 Stopping existing container..."
docker stop webapp-container 2>/dev/null || true
docker rm webapp-container 2>/dev/null || true

# Start new container with AWS credentials
echo "🚀 Starting container with CloudWatch integration..."
docker run -d \
    --name webapp-container \
    -p 5000:5000 \
    --restart unless-stopped \
    -e AWS_DEFAULT_REGION=us-east-1 \
    -e AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id)" \
    -e AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key)" \
    cloud-webapp

# Wait for container to start
echo "⏳ Waiting for application to start..."
sleep 10

# Test application
echo "🧪 Testing application..."
if curl -f http://localhost:5000/health &>/dev/null; then
    echo "✅ Application is healthy"
else
    echo "❌ Application health check failed"
    exit 1
fi

# Test CloudWatch integration
echo "🔬 Testing CloudWatch integration..."
RESPONSE=$(curl -s http://localhost:5000/cloudwatch-test)
if echo "$RESPONSE" | grep -q "successfully"; then
    echo "✅ CloudWatch integration working"
else
    echo "⚠️  CloudWatch integration may have issues"
fi

# Setup monitoring and alerts
echo "📊 Setting up CloudWatch monitoring..."
chmod +x scripts/setup-cloudwatch.sh
./scripts/setup-cloudwatch.sh

# Setup auto-recovery cron job
echo "🔄 Setting up auto-recovery..."
chmod +x scripts/auto-recovery.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/$(whoami)/cloud-webapp-project/scripts/auto-recovery.sh") | crontab -

echo "✅ Deployment complete!"
echo "🌐 Application URL: http://$(curl -s http://checkip.amazonaws.com):5000"
echo "📊 CloudWatch Console: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#metricsV2:graph=~();namespace=CloudWebApp/Metrics"
echo "🔔 Check your email for SNS subscription confirmation"