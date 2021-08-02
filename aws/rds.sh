#!/bin/sh

# Définition des variables :
AWS_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
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
identif_dev_test="RDSTEST2"
identif_prod="RDSPROD"
rds_port="3306"
db_name="projet_devops_2021"
VPC_DEF_ID="vpc-13153e7a"

# 1 default VPC / zone ==> on renseigne l'id du VPC en param 
echo "ID du VPC par defaut: $VPC_DEF_ID"

# Création de 2 sous réseau dans le default vpc
DbSubnetID_1=$(aws ec2 create-subnet --vpc-id "$VPC_DEF_ID" --cidr-block 172.31.48.0/24 --availability-zone $SUBNET_RDS_b --query 'Subnet.{SubnetId:SubnetId}' --output text)
DbSubnetID_2=$(aws ec2 create-subnet --vpc-id "$VPC_DEF_ID" --cidr-block 172.31.64.0/24 --availability-zone $SUBNET_RDS_a --query 'Subnet.{SubnetId:SubnetId}' --output text)

# Ajout d'un tag au 2 subnet
aws ec2 create-tags --resources "$DbSubnetID_1" --tags 'Key=Name,Value=GRP1-b-DB-Subnet'
aws ec2 create-tags --resources "$DbSubnetID_2" --tags 'Key=Name,Value=GRP1-c-DB-Subnet'

echo "ID des 2 Subnet RDS : $DbSubnetID_1 & $DbSubnetID_2"
# Création d'un grp de secu pour la RDS
dbSecGrpID=$(aws ec2 create-security-group \
           --group-name dbSecGrp \
           --description "Security Group for database servers" \
           --vpc-id "$VPC_DEF_ID" \
           --output text)
# ajout tag au grp de secu
aws ec2 create-tags --resources $dbSecGrpID --tags Key=Name,Value="GRP1_dbSecGrp"

# Ajout de la regle autorisation port 3306
aws ec2 authorize-security-group-ingress \
        --group-id "$dbSecGrpID" \
        --protocol tcp \
        --port 3306 \
        --cidr 0.0.0.0/0

echo "Groupe de securité créé avec ouverture du port 3306"

# Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two AZs in the region
DBSUBNET_GROUP=$(aws rds create-db-subnet-group \
        --db-subnet-group-name "GRP1-MYSQLDBSUBNET_GROUP" \
        --db-subnet-group-description "Subnet group for RDS databases instances" \
        --subnet-ids "$DbSubnetID_1" "$DbSubnetID_2" \
        --output text --query 'DBSubnetGroup[0].Subnets.{SubnetIdentifier:SubnetIdentifier}' )


# RDS - MySQL Instance
aws rds create-db-instance --allocated-storage 10 \
	--db-instance-class $Class_dev_test \
	--db-instance-identifier $identif_dev_test \
	--publicly-accessible  \
	--engine "mysql" --availability-zone $SUBNET_RDS_b \
    --vpc-security-group-ids "$dbSecGrpID" \
	--port $rds_port --db-name $db_name --master-username $admin \
	--master-user-password $Password


# Waiting RDS to be status available, showing progess state
echo "RDS Status :" 
status=$(aws rds describe-db-instances --db-instance-identifier $identif_dev_test --output text --query 'DBInstances[0].DBInstanceStatus')
tmp=""
while [ "$status" != "available" ]
do
    if [ "$status" != "$tmp" ]
    then
        tmp=$status
        echo "$tmp ..."
    fi
    sleep 5
    status=$(aws rds describe-db-instances --db-instance-identifier $identif_dev_test --output text --query 'DBInstances[0].DBInstanceStatus')
done
echo "RDS is available!" 

# get RDS EndPoint
endpoint=$(aws rds describe-db-instances --db-instance-identifier $identif_dev_test --output text --query 'DBInstances[0].Endpoint.{Address:Address}')

# exec SQL scipt on RDS DB
mysql -h $endpoint -P $rds_port  -u $admin -p$Password < projet_devops_2021.sql

# exec du script de creation VPC et EC2 instances
. create-infra.sh

# append RDS EndPoint to infra_ID.tx
echo "[RDS]
user = $admin
pwd = $Password
host = $endpoint
bd = $db_name
" >> infra_ID.txt