#!/bin/bash

# Real-time monitoring dashboard
echo "🚀 Cloud Web App Monitoring Dashboard"
echo "======================================"

while true; do
    clear
    echo "🚀 Cloud Web App Monitoring Dashboard - $(date)"
    echo "======================================"
    
    # Container Status
    echo "🐳 Container Status:"
    if docker ps | grep -q webapp-container; then
        echo "   ✅ Container: Running"
        CONTAINER_ID=$(docker ps | grep webapp-container | awk '{print $1}')
        echo "   📊 Container ID: $CONTAINER_ID"
    else
        echo "   ❌ Container: Not Running"
    fi
    echo
    
    # Application Health
    echo "💚 Application Health:"
    HEALTH_RESPONSE=$(curl -s http://localhost:5000/health 2>/dev/null)
    if [ $? -eq 0 ]; then
        STATUS=$(echo $HEALTH_RESPONSE | jq -r '.status' 2>/dev/null || echo "unknown")
        UPTIME=$(echo $HEALTH_RESPONSE | jq -r '.uptime' 2>/dev/null || echo "0")
        echo "   Status: $STATUS"
        echo "   Uptime: $(printf "%.0f" $UPTIME) seconds"
    else
        echo "   ❌ Health check failed"
    fi
    echo
    
    # System Metrics
    echo "📊 System Metrics:"
    METRICS_RESPONSE=$(curl -s http://localhost:5000/metrics 2>/dev/null)
    if [ $? -eq 0 ]; then
        CPU=$(echo $METRICS_RESPONSE | jq -r '.cpu_percent' 2>/dev/null || echo "N/A")
        MEMORY=$(echo $METRICS_RESPONSE | jq -r '.memory_percent' 2>/dev/null || echo "N/A")
        DISK=$(echo $METRICS_RESPONSE | jq -r '.disk_usage' 2>/dev/null || echo "N/A")
        echo "   🖥️  CPU Usage: ${CPU}%"
        echo "   💾 Memory Usage: ${MEMORY}%"
        echo "   💿 Disk Usage: ${DISK}%"
    else
        echo "   ❌ Metrics unavailable"
    fi
    echo
    
    # CloudWatch Status
    echo "☁️  CloudWatch Integration:"
    if aws cloudwatch list-metrics --namespace CloudWebApp/Metrics --query 'Metrics[0].MetricName' --output text 2>/dev/null | grep -q .; then
        echo "   ✅ CloudWatch: Connected"
        LAST_DATAPOINT=$(aws cloudwatch get-metric-statistics \
            --namespace CloudWebApp/Metrics \
            --metric-name CPUUtilization \
            --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
            --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
            --period 300 \
            --statistics Average \
            --query 'Datapoints[-1].Timestamp' \
            --output text 2>/dev/null)
        echo "   📊 Last Metric: $LAST_DATAPOINT"
    else
        echo "   ❌ CloudWatch: Not connected"
    fi
    echo
    
    echo "Press Ctrl+C to exit, refreshing in 10 seconds..."
    sleep 10
done