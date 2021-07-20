#!/bin/sh

# Définition des variables :
AWS_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
#### RDS
Identifier="SGBD_TEST"
Engine="mysql"
Ava_Zone="us-east-1b"
DbName="DB_Equipe_1_TEST"
SUBNET_RDS_a=$AWS_REGION"a"
SUBNET_RDS_b=$AWS_REGION"b"
admin="admin"
Password="Password123"
Class_dev_test="db.r5.large"
Class_prod="db.r5.xlarge"
identif_dev_test="RDSTEST"
identif_prod="RDSPROD"
rds_port="3306"
db_name="projet_devops_2021"
VPC_DEF_ID="vpc-13153e7a"
## RDS Create


# aws ec2 create-tags --resources $VPC_DEF_ID --tags Key=Name,Value=$VPC_NAME"_default"

echo "ID du VPC par defaut: $VPC_DEF_ID"


DbSubnetID_1=$(aws ec2 create-subnet --vpc-id "$VPC_DEF_ID" --cidr-block 172.31.48.0/24 --availability-zone $SUBNET_RDS_b --query 'Subnet.{SubnetId:SubnetId}' --output text)
DbSubnetID_2=$(aws ec2 create-subnet --vpc-id "$VPC_DEF_ID" --cidr-block 172.31.64.0/24 --availability-zone $SUBNET_RDS_a --query 'Subnet.{SubnetId:SubnetId}' --output text)


aws ec2 create-tags --resources "$DbSubnetID_1" --tags 'Key=Name,Value=GRP1-b-DB-Subnet'
aws ec2 create-tags --resources "$DbSubnetID_2" --tags 'Key=Name,Value=GRP1-c-DB-Subnet'


dbSecGrpID=$(aws ec2 create-security-group \
           --group-name dbSecGrp \
           --description "Security Group for database servers" \
           --vpc-id "$VPC_DEF_ID" \
           --output text)

aws ec2 authorize-security-group-ingress \
        --group-id "$dbSecGrpID" \
        --protocol tcp \
        --port 3306 \
        --cidr 0.0.0.0/0

# aws rds create-db-parameter-group \
#     --db-parameter-group-name myParamGrp \
#     --db-parameter-group-family MySQL5.6 \
#     --description "My new parameter group"

# aws rds modify-db-parameter-group --db-parameter-group-name myParamGrp --parameters "ParameterName=general_log, ParameterValue=ON, Description=logParameter,ApplyMethod=immediate"

echo "ID des 2 Subnet RDS : $DbSubnetID_1 & $DbSubnetID_2"

DBSUBNET_GROUP=$(aws rds create-db-subnet-group \
        --db-subnet-group-name "GRP1-MYSQLDBSUBNET_GROUP" \
        --db-subnet-group-description "Subnet group for RDS databases instances" \
        --subnet-ids "$DbSubnetID_1" "$DbSubnetID_2" \
        --output text --query 'DBSubnetGroup[0].Subnets.{SubnetIdentifier:SubnetIdentifier}' )

# aws ec2 create-tags --resources "$DBSUBNET_GROUP" --tags 'Key=Name,Value=GRP1-DBSUBNET_GROUP'

# echo ID du Subnet Group RDS $DBSUBNET_GROUP

aws rds create-db-instance --allocated-storage 10 \
	--db-instance-class $Class_dev_test \
	--db-instance-identifier $identif_dev_test \
	--publicly-accessible  \
	--engine "mysql" --availability-zone $SUBNET_RDS_b \
    --vpc-security-group-ids "$dbSecGrpID" \
	--port $rds_port --db-name $db_name --master-username $admin \
	--master-user-password $Password

echo "creating RDS test DB ..."
status=$(aws rds describe-db-instances --db-instance-identifier $identif_dev_test --output text --query 'DBInstances[0].DBInstanceStatus')

while [ "$status" != "available" ]
do
    sleep 5
    status=$(aws rds describe-db-instances --db-instance-identifier $identif_dev_test --output text --query 'DBInstances[0].DBInstanceStatus')
done
echo "DB is running" 

endpoint=$(aws rds describe-db-instances --db-instance-identifier $identif_dev_test --output text --query 'DBInstances[0].Endpoint.{Address:Address}')

mysql -h $endpoint -P $rds_port  -u $admin -p$Password < projet_devops_2021.sql

. create-vpc.sh

echo "RDS_ENDPOINT_ADRESS_TEST: $endpoint" >> infra_ID.txt