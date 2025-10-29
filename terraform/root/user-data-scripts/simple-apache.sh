#!/bin/bash

# Update system
yum update -y

# Install Apache
yum install -y httpd

# Create a simple HTML page
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Web Server</title>
</head>
<body>
    <h1>Welcome to Apache Server</h1>
    <p>Server: $(hostname -f)</p>
    <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
    <p>Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
    <p>Date: $(date)</p>
</body>
</html>
EOF

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Ensure Apache is running
systemctl status httpd

# Create a simple health check endpoint
echo "OK" > /var/www/html/health

# Log completion
echo "User data script completed at $(date)" >> /var/log/user-data.log