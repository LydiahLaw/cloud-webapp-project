from flask import Flask, render_template, jsonify
import psutil
import time
import os
import boto3
import json
from datetime import datetime
from botocore.exceptions import ClientError

app = Flask(__name__)

# Initialize CloudWatch client
try:
    cloudwatch = boto3.client('cloudwatch', region_name='us-east-1')
    print("CloudWatch client initialized successfully")
except Exception as e:
    print(f"CloudWatch initialization failed: {e}")
    cloudwatch = None

def send_custom_metric(metric_name, value, unit='Percent'):
    """Send custom metrics to CloudWatch"""
    if cloudwatch:
        try:
            cloudwatch.put_metric_data(
                Namespace='CloudWebApp/Metrics',
                MetricData=[
                    {
                        'MetricName': metric_name,
                        'Value': value,
                        'Unit': unit,
                        'Timestamp': datetime.utcnow()
                    }
                ]
            )
            print(f"Sent metric {metric_name}: {value}")
        except Exception as e:
            print(f"Failed to send metric {metric_name}: {e}")

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/health')
def health_check():
    try:
        # Perform basic health checks
        cpu_percent = psutil.cpu_percent()
        memory_percent = psutil.virtual_memory().percent
        disk_percent = psutil.disk_usage('/').percent
        
        # Determine health status
        status = 'healthy'
        if cpu_percent > 80 or memory_percent > 80 or disk_percent > 90:
            status = 'unhealthy'
        
        # Send health status to CloudWatch
        health_score = 100 if status == 'healthy' else 0
        send_custom_metric('HealthStatus', health_score, 'None')
        
        return jsonify({
            'status': status,
            'timestamp': datetime.now().isoformat(),
            'uptime': time.time() - start_time,
            'cpu_percent': cpu_percent,
            'memory_percent': memory_percent,
            'disk_percent': disk_percent
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/metrics')
def metrics():
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory_percent = psutil.virtual_memory().percent
        disk_percent = psutil.disk_usage('/').percent
        
        # Send metrics to CloudWatch
        send_custom_metric('CPUUtilization', cpu_percent)
        send_custom_metric('MemoryUtilization', memory_percent)
        send_custom_metric('DiskUtilization', disk_percent)
        
        return jsonify({
            'cpu_percent': round(cpu_percent, 2),
            'memory_percent': round(memory_percent, 2),
            'disk_usage': round(disk_percent, 2),
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/cloudwatch-test')
def cloudwatch_test():
    """Test endpoint to verify CloudWatch integration"""
    try:
        # Send a test metric
        send_custom_metric('TestMetric', 42, 'Count')
        return jsonify({
            'message': 'CloudWatch test metric sent successfully',
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            'error': f'CloudWatch test failed: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

if __name__ == '__main__':
    start_time = time.time()
    print("Starting Cloud Monitoring Dashboard...")
    print("CloudWatch integration:", "enabled" if cloudwatch else "disabled")
    app.run(host='0.0.0.0', port=5000, debug=False)