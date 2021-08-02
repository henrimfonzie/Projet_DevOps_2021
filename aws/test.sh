Class=db.t2.micro
Identifier=azerty1254
Subnet=subnet-0cfaa878e30156bc2
VpcID=vpc-0faac9d984bb7d6e4
VPC_ID=vpc-0faac9d984bb7d6e4
vpcID=vpc-0faac9d984bb7d6e4
SUBNET_PUBLIC_ID=subnet-0d51630352d7230dc
SUBNET_PRIVATE_ID=subnet-03932db299cba0fb0
GATEWAY_ID=igw-00d6a3ab836858b90
ROUTE_TABLE_ID=rtb-044ff764813e771c7
SECURITY_GROUP_ID=sg-0612019b67d127ceb
SGRP=sg-0612019b67d127ceb
AWS_DEFAULT_REGION=us-east-1
#AWS_DEFAULT_REGION=eu-west-3

#aws_default_subnet="subnet-03932db299cba0fb0" 
availability_zone="us-east-1b"
#aws ec2 create-default-subnet --availability-zone us-east-1a
aws ec2 create-default-subnet --availability-zone us-east-1b



dbSecGrpID=$(aws ec2 create-security-group \
           --group-name GRP_1_Secuity-Group_RDS \
           --description "Security Group RDS database servers" \
           --vpc-id "$vpcID" \
           --output text)


echo "------- "
echo ID du groupe de Securite RDS
echo $dbSecGrpID
echo " --------"
echo " "
sleep 5

DbSubnetID=$(aws ec2 create-subnet --vpc-id "$VpcID" --cidr-block 10.0.5.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)
echo " "
echo "------- "
echo ID du Subnet RDS
echo $DbSubnetID
echo " --------"
echo " "
sleep 11

echo " "
echo "------- "
echo ID du Subnet RDS new
echo $DbSubnetID
echo " --------"

aws ec2 create-tags --resources "$DbSubnetID" --tags 'Key=Name,Value=GRP1-us-east-DB-Subnet'

#aws rds create-db-instance --allocated-storage 5 --db-instance-class $Class --db-instance-identifier $Identifier --engine mysql --availability-zone us-east-1 --port 3306 --db-name projet --master-username admin --master-user-password Password123 --vpc-security-group-ids "$dbSecGrpID"
aws rds create-db-instance --allocated-storage 5 --db-instance-class $Class --db-instance-identifier $Identifier --engine mysql --availability-zone us-east-1b --port 3306 --db-name projet --master-username admin --master-user-password Password123 --vpc-security-group-ids "$dbSecGrpID"

#aws ec2 create-tags --resources "$USEast1b_DbSubnetID" --tags 'Key=Name,Value=az1-us-east-1b-DB-Subnet
