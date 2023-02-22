#!/bin/bash

# Update the system
sudo apt update

# Install Java
sudo apt install default-jdk -y

# Download and extract SonarQube
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.9.2.46101.zip
unzip sonarqube-8.9.2.46101.zip

# Move SonarQube directory to /opt
sudo mv sonarqube-8.9.2.46101 /opt/sonarqube

# Create a new user to run SonarQube
sudo useradd -r sonarqube
sudo chown -R sonarqube:sonarqube /opt/sonarqube

# Create a Systemd service file for SonarQube
sudo tee /etc/systemd/system/sonarqube.service <<EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=simple
User=sonarqube
Group=sonarqube
WorkingDirectory=/opt/sonarqube
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload Systemd and start SonarQube
sudo systemctl daemon-reload
sudo systemctl start sonarqube
sudo systemctl enable sonarqube

# Save and give executable access
#chmod +x install_sonarqube.sh
#./install_sonarqube.sh
