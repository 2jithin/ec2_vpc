sudo systemctl start jenkins
sudo tar -xzvf jenkins-backup.tar.gz -C /var/lib/

sudo chown -R jenkins:jenkins /var/lib/jenkins
sudo chmod -R 755 /var/lib/jenkins

sudo systemctl start jenkins

