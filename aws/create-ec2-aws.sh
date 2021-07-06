# Lancer l'instance EC2
AWS_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
VPC_NAME="Vanessa VPC"
VPC_CIDR="10.0.0.0/16"
SUBNET_PUBLIC_CIDR="10.0.1.0/24"
SUBNET_PUBLIC_AZ=$AWS_REGION"a"
SUBNET_PUBLIC_NAME="10.0.1.0 - "$AWS_REGION"a"
SUBNET_PRIVATE_CIDR="10.0.2.0/24"
SUBNET_PRIVATE_AZ=$AWS_REGION"b"
SUBNET_PRIVATE_NAME="10.0.2.0 - "$AWS_REGION"b"
CHECK_FREQUENCY=5
KEY_NAME="xxxxxxxxxxxxxxxxxxx"
IMAGE_ID="ami-00c08ad1a6ca8ca7c"

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $IMAGE_ID \
    --count 1 \
    --instance-type t2.micro \
    --key-name $KEY_NAME \
    --security-group-ids $GROUP_ID \
    --subnet-id $SUBNET_PUBLIC_ID \
    --user-data file://script_deploiement.sh | sudo  jq '.Instances[0].InstanceId' | sed -e 's/^"//' -e 's/"$//' )

echo "L'instance est lancée avec l'ID "$INSTANCE_ID

# Récupérer l'adresse IP Publique de l'instance :
INSTANCE_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text )

echo "Instance prête à être utilisée"
echo "Veuillez effectuer les dernières étapes sur http://"$INSTANCE_IP
