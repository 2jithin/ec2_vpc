#!/bin/bash
ec2type=""
read -p "Enter number of instance count you want eg; 1,2,3.. : " count

echo "You are requested to provision :, $count , instance"

echo "Please select Amazon linux instance (AMI) type (Enter Numerical value):"
echo "1. t2.small"
echo "2. t2.medium"
echo "3. t2.large"
echo "4. Quit"

read -p "Enter your choice [1-4]: " choice

case $choice in
  1)
    echo "You chose Option t2.small"
    # Add code for Option One here
    ec2type=t2.small
    ;;
  2)
    echo "You chose Option t2.medium"
    # Add code for Option Two here
    ec2type=t2.medium
    ;;
  3)
    echo "You chose Option t2.large"
    # Add code for Option Three here
    ec2type=t2.large
    ;;
  4)
    echo "Goodbye!"
    exit 0
    ;;
  *)
    echo "Invalid choice, please try again."
    ;;
esac

echo "provisioning $count of Amazon linux Instance as $ec2type along with VPC,Subnet,SG,IGateway,RouteTable also will be installed \n 1.java-11 \n2.git]\n 3.Docker \n4.Docker-Compose "

# Set the VPC and subnet CIDR blocks
VPC_CIDR_BLOCK="10.0.0.0/16"
SUBNET_CIDR_BLOCK="10.0.1.0/24"

# Create the VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR_BLOCK --query 'Vpc.VpcId' --output text)

# Enable DNS hostname support for the VPC
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames '{"Value":true}'

# Create an Internet Gateway and attach it to the VPC
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# Create a public subnet within the VPC
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR_BLOCK --query 'Subnet.SubnetId' --output text)

# Create a Route Table for the public subnet and add a default route to the Internet Gateway
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET_ID
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

# Create a Security Group to allow SSH and Jenkins access to the instance
SG_ID=$(aws ec2 create-security-group --group-name docker-composet2Medium --description "Security group for SSH access" --vpc-id $VPC_ID --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 8080 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 9000 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 4243 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 8228 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 2377 --cidr 0.0.0.0/0

# Launch an EC2 instance in the public subnet with the specified Security Group, key pair, and userdata
INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0cc87e5027adcdca8 --count $count --instance-type $ec2type --security-group-ids $SG_ID --subnet-id $SUBNET_ID --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=docker,Value=Test}]' 'ResourceType=volume,Tags=[{Key=docker, Value=Test}]' --user-data "#!/bin/bash
sudo yum update -y
sudo yum install java-11-openjdk-devel -y
sudo yum install git -y
sudo yum install docker -y
sudo sed -i '/^ExecStart=/c ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:4243 -H fd:// --containerd=/run/containerd/containerd.sock $OPTIONS $DOCKER_STORAGE_OPTIONS $DOCKER_ADD_RUNTIMES'
sudo usermod -aG docker $USER
sudo service docker stop
sudo chmod 666 /var/run/docker.sock
sudo systemctl daemon-reload
sudo systemctl start docker
sudo curl -L "https://github.com/docker/compose/releases/download/v2.17.0-rc.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
source ~/.bash_profile
mkdir clonnedfolder
git clone https://github.com/2jithin/ec2_vpc.git
cd ec2_vpc/
git config core.sparseCheckout true
echo "swarmDockertest/" >> .git/info/sparse-checkout
git read-tree -mu HEAD
cd /ec2_vpc/swarmDockertest/") # --query 'Instances[0].InstanceId' --output text

# added sonar group without user access bin/false

echo "$INSTANCE_ID" > ec2instanceDetail.json

cat ec2instanceDetail.json
# Wait for the instance to be in a running state

# result=$(jq '.Instances[].InstanceId' test.json)

# echo "Instance id is $result"

aws ec2 describe-instances --query 'Reservations[0].Instances[0].[InstanceId, Tags[?Key==`docker`].Value[]]'

INSTANCEID=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].InstanceId" --output json)

echo "========== WAIT for Instance ============="

sleep 20
aws ec2 wait instance-running --instance-ids $INSTANCEID

echo "========== Public IP for Instance ============="

# Get the public IP address of the instance
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCEID --query 'Reservations[*].Instances[*].PublicIpAddress' --output json)

echo "Your Public IP address of instances is  $PUBLIC_IP"

# May be for jenkins need to install jdk11
# sudo yum update -y

# # Install JDK 11
# sudo amazon-linux-extras install java-openjdk11 -y
# may be we can remove sudo yum remove java-1.7.0-openjdk
# then must update the environment
# echo $"export PATH=$PATH:/usr/lib/jvm/java-11-openjdk-11.0.16.0.8-1.amzn2.0.1.x86_64/bin/" >> ~/.bash_profile
# source ~/.bash_profile
