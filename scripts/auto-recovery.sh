#!/bin/bash

# Automated recovery script for the web application
LOG_FILE="/var/log/webapp-recovery.log"
CONTAINER_NAME="webapp-container"
IMAGE_NAME="cloud-webapp"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

check_container_health() {
    if docker ps | grep -q $CONTAINER_NAME; then
        # Container is running, check health
        HEALTH_STATUS=$(curl -s http://localhost:5000/health | jq -r '.status' 2>/dev/null || echo "error")
        
        if [ "$HEALTH_STATUS" = "healthy" ]; then
            log_message "✅ Container is healthy"
            return 0
        else
            log_message "❌ Container is unhealthy (status: $HEALTH_STATUS)"
            return 1
        fi
    else
        log_message "❌ Container is not running"
        return 1
    fi
}

restart_container() {
    log_message "🔄 Attempting to restart container..."
    
    # Stop and remove existing container
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    
    # Start new container
    docker run -d \
        --name $CONTAINER_NAME \
        -p 5000:5000 \
        --restart unless-stopped \
        -e AWS_DEFAULT_REGION=us-east-1 \
        $IMAGE_NAME
    
    if [ $? -eq 0 ]; then
        log_message "✅ Container restarted successfully"
        
        # Send recovery notification
        aws sns publish \
            --topic-arn "arn:aws:sns:us-east-1:$(aws sts get-caller-identity --query Account --output text):CloudWebAppAlerts" \
            --message "🔄 Cloud Web App has been automatically recovered at $(date)" \
            --subject "Auto-Recovery: Application Restored" 2>/dev/null || true
    else
        log_message "❌ Failed to restart container"
        
        # Send failure notification
        aws sns publish \
            --topic-arn "arn:aws:sns:us-east-1:$(aws sts get-caller-identity --query Account --output text):CloudWebAppAlerts" \
            --message "❌ Cloud Web App auto-recovery FAILED at $(date). Manual intervention required." \
            --subject "CRITICAL: Auto-Recovery Failed" 2>/dev/null || true
    fi
}

# Main recovery logic
log_message "🔍 Checking container health..."

if ! check_container_health; then
    restart_container
else
    log_message "✅ No recovery needed"
fi