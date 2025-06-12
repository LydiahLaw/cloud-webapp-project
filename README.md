# Cloud-Native Flask Web App with Docker, EC2, and CloudWatch Monitoring

This project demonstrates how to build, deploy, and monitor a containerized Flask web application using AWS services. It includes real-time health checks, custom metrics, and alerting via SNS.

## Overview

The goal of this project is to simulate a real-world cloud-native web application setup with observability and automation.

## What the App Does

- A Python Flask app with:
  - `/health` endpoint for health checks
  - `/metrics` endpoint for system resource stats
- Dockerized and deployed on EC2
- Monitored using AWS CloudWatch
- Alarms created for high CPU, high memory, and unhealthy status
- Email notifications via SNS when thresholds are breached

## Architecture

- Flask App → Docker Container → EC2
- CloudWatch Agent installed on EC2 to send metrics
- CloudWatch Alarms monitor app and instance metrics
- SNS topic delivers alerts via email

## Technologies Used

- Python Flask
- Docker
- AWS EC2 (t2.micro)
- Amazon CloudWatch
- AWS SNS
- IAM Roles and Policies
- Shell scripting for deployment

## How to Use

1. Clone the repo to your local machine.
2. Build the Docker image:
3. Deploy to EC2:
- Create an EC2 instance
- SSH into the instance and install Docker
- Run the app using the `deploy-with-monitoring.sh` script

4. Install and configure the CloudWatch agent
5. Set up alarms in CloudWatch and link them to an SNS topic
6. Subscribe your email to receive alerts

## Key Learnings

- Automating app deployment using Docker and user data
- Managing permissions via IAM roles for monitoring
- Sending custom metrics to CloudWatch
- Creating actionable alarms and alerts
- Debugging SNS subscription and alarm configuration issues

## Status

The app is live on an EC2 instance and fully monitored. SNS alerts are working, and CloudWatch alarms are triggered based on defined thresholds.

## Author

Lydiah, Cloud & DevOps | [cloudwithlydiah.com](https://cloudwithlydiah.com)
