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
IMAGE_ID="ami-0f7cd40eac2214b37"
ENV_JENK="jenkins"
ENV_DEV="dev"
ENV_PROD="prod"
ENV_TEST="test"
ENV_NEXUS="nexus"
ENV_MySQL="MySQL"
 
INSTANCE_ID_MySQL_DEV=$(aws_create_RDS "$ENV_MySQL")


#aws rds modify-db-instance --db-instance-identifier "$rdsInstID" --db-parameter-group-name myParamGrp

 aws_create_RDS(){
		 rdsInstID="rds-mysql-inst01"
                 ID=$(aws rds create-db-instance \
                      	--db-instance-identifier $rdsInstID \
      			--allocated-storage 5 \
			--db-instance-class db.t2.medium \
		        --no-multi-az \
		        --no-auto-minor-version-upgrade \
 		        --availability-zone us-east-1 \
			--vpc-security-group-ids sg-008df419a48de4b28\
		        --db-subnet-group-name \
		        --engine mysql \
		        --port 3306 \
		        --master-username admin \
		        --master-user-password admin \
		        --db-parameter-group-name \
		        --db-name projet_devops_2021_DEV \
		        --backup-retention-period 3)


