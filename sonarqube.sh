#!/bin/bash

# Update system packages
sudo apt update

# Install OpenJDK
sudo apt install -y openjdk-11-jdk
sudo apt install -y unzip
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Create PostgreSQL database and user
sudo -u postgres createuser sonar
sudo -u postgres createdb -O sonar sonarqube

# Download and extract SonarQube
wget https://binaries.sonarsource.com/CommercialDistribution/sonarqube-developer/sonarqube-developer-9.1.0.47736.zip
unzip sonarqube-developer-9.1.0.47736.zip

# Configure SonarQube properties
echo "sonar.jdbc.username=sonar" >> sonarqube-9.1.0.47736/conf/sonar.properties
echo "sonar.jdbc.password=localTest@123" >> sonarqube-9.1.0.47736/conf/sonar.properties
echo "sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube" >> sonarqube-9.1.0.47736/conf/sonar.properties

# Create systemd service file
# Use thr exact path for Excec where you have unziped that
sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/home/ubuntu/sonarqube-9.1.0.47736/bin/linux-x86-64/sonar.sh start
ExecStop=/home/ubuntu/sonarqube-9.1.0.47736/bin/linux-x86-64/sonar.sh stop
User=ubuntu
Group=ubuntu
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start and enable SonarQube service
sudo systemctl daemon-reload
sudo systemctl start sonarqube
sudo systemctl enable sonarqube

echo "SonarQube installation completed."

# Clean up downloaded files
rm sonarqube-developer-9.1.0.47736.zip
