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
 
# Lancer l'instance EC2
 
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0f7cd40eac2214b37 \
    --count 1 \
    --instance-type t2.micro \
    --key-name KEY_NAME \
    --security-group-ids  sg-0c2548da0d7049ffb \
    --subnet-id  subnet-08d5819a206b434e2\
    --user-data file://install-jenkins-ansible.sh)
 
echo "L'instance est lancée avec l'ID "$INSTANCE_ID
 
# Récupérer l'adresse IP Publique de l'instance :
INSTANCE_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text )
 
echo "Instance Jenkins prete à être utilisée"
