#!/bin/bash

# Définition des variables :
AWS_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
VPC_NAME="VPC_Equipe_1"
VPC_CIDR="10.0.0.0/16"
SUBNET_PUBLIC_CIDR="10.0.1.0/24"
SUBNET_PUBLIC_AZ=$AWS_REGION"a"
SUBNET_PUBLIC_NAME="10.0.1.0 - "$AWS_REGION"a"
SUBNET_PRIVATE_CIDR="10.0.2.0/24"
SUBNET_PRIVATE_AZ=$AWS_REGION"b"
SUBNET_PRIVATE_NAME="10.0.2.0 - "$AWS_REGION"b"
CHECK_FREQUENCY=5
KEY_NAME="key_Equipe_1"
IMAGE_ID="ami-00c08ad1a6ca8ca7c"

# Creation VPC
echo "Creation VPC"
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --query 'Vpc.{VpcId:VpcId}' \
  --output text )
echo "  VPC ID '$VPC_ID' CREATED in '$AWS_REGION' region."

# Creation sous-réseau Public 
echo "Creation sous-réseau Public "
SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $SUBNET_PUBLIC_CIDR \
  --availability-zone $SUBNET_PUBLIC_AZ \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text )
echo "  Subnet ID '$SUBNET_PUBLIC_ID' CREATED in '$SUBNET_PUBLIC_AZ'" \
  "Availability Zone."

# Create Private Subnet
echo "Creating Private Subnet..."
SUBNET_PRIVATE_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $SUBNET_PRIVATE_CIDR \
  --availability-zone $SUBNET_PRIVATE_AZ \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text )
echo "  Subnet ID '$SUBNET_PRIVATE_ID' CREATED in '$SUBNET_PRIVATE_AZ'" \
  "Availability Zone."

# Create Internet gateway
echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
  --output text )
echo "  Internet Gateway ID '$IGW_ID' CREATED."

# Attach Internet gateway to your VPC
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID 
echo "  Internet Gateway ID '$IGW_ID' ATTACHED to VPC ID '$VPC_ID'."
