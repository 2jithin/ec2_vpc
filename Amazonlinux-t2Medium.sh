#!/bin/bash

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
SG_ID=$(aws ec2 create-security-group --group-name sonarqubet2Medium --description "Security group for SSH access" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 8080 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 9000 --cidr 0.0.0.0/0

# Launch an EC2 instance in the public subnet with the specified Security Group, key pair, and userdata
INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0cc87e5027adcdca8 --count 1 --instance-type t2.medium --security-group-ids $SG_ID --subnet-id $SUBNET_ID --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=sonarqube,Value=Test}]' 'ResourceType=volume,Tags=[{Key=sonarqube, Value=Test}]'--user-data "#!/bin/bash
sudo yum update -y
sudo yum install java-11-openjdk-devel -y
#sudo useradd -r -s /bin/false sonar -g sonar
source ~/.bash_profile") # --query 'Instances[0].InstanceId' --output text

# added sonar group without user access bin/false

echo "Instance ID --output: $INSTANCE_ID" > test.json

cat test.json
# Wait for the instance to be in a running state

# result=$(jq '.Instances[].InstanceId' test.json)

# echo "Instance id is $result"

aws ec2 describe-instances —filters name=sonarqube, Values=Test

aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get the public IP address of the instance
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress')

# May be for jenkins need to install jdk11
# sudo yum update -y

# # Install JDK 11
# sudo amazon-linux-extras install java-openjdk11 -y
# may be we can remove sudo yum remove java-1.7.0-openjdk
# then must update the environment
# echo $"export PATH=$PATH:/usr/lib/jvm/java-11-openjdk-11.0.16.0.8-1.amzn2.0.1.x86_64/bin/" >> ~/.bash_profile
# source ~/.bash_profile
