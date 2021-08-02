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
 
#Function Create Key SSH with exist check
aws_ssh_key_gen(){
	KEY=$1
	if aws ec2 wait key-pair-exists --key-names $KEY
		then
		echo "La clé $KEY existe déjà, on la supprime!"
		aws ec2 delete-key-pair --key-name $KEY
	fi
	 
	if test -f "./keys/$KEY.pem"
		then
		sudo rm -f ./keys/$KEY.pem
	fi
	 
	aws ec2 create-key-pair \
		--key-name $KEY \
		--query 'KeyMaterial' \
		--output text > $KEY.pem
	 
	echo " $KEY.pem Créée!"
	chmod 400 $KEY.pem

}

aws_set_tcp(){
	GROUP=$1
	PORT=$2
	aws ec2 authorize-security-group-ingress \
		--group-id $GROUP \
		--protocol tcp \
		--port $PORT \
		--cidr 0.0.0.0/0
}

aws_create_EC2(){
	NAME=$KEY_NAME"_"$1
	if [ "$#" -eq 2 ]
	then
		File=$2
		ID=$(aws ec2 run-instances \
			--image-id $IMAGE_ID \
			--count 1 \
			--instance-type t2.medium \
			--key-name $NAME \
			--security-group-ids $GROUP_ID \
			--subnet-id $SUBNET_PUBLIC_ID \
			--user-data file://$File | sudo jq '.Instances[0].InstanceId' | sed -e 's/^"//' -e 's/"$//' )

	else
		ID=$(aws ec2 run-instances \
			--image-id $IMAGE_ID \
			--count 1 \
			--instance-type t2.medium \
			--key-name $NAME \
			--security-group-ids $GR $GROUP_IDOUP_ID \
			--subnet-id $SUBNET_PUBLIC_ID | sudo jq '.Instances[0].InstanceId' | sed -e 's/^"//' -e 's/"$//' )
	fi
	aws ec2 create-tags --resources $ID --tags Key=Name,Value="GRP1_EC2_$1"
  echo $ID
}
# Creation VPC
echo "Creation VPC"
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --query 'Vpc.{VpcId:VpcId}' \
  --output text )
echo "  VPC ID '$VPC_ID' CREATED in '$AWS_REGION' region."

# Creation d'un Nom de VPC
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$VPC_NAME

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
 
aws ec2 create-tags --resources $SUBNET_PUBLIC_ID --tags Key=Name,Value="GRP1_Pub_SubNet"

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
  
aws ec2 create-tags --resources $SUBNET_PRIVATE_ID --tags Key=Name,Value="GRP1_Priv_SubNet"
 
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
 
# Create Route Table
echo "Creating Route Table..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.{RouteTableId:RouteTableId}' \
  --output text )
echo "  Route Table ID '$ROUTE_TABLE_ID' CREATED."
 
# Create route to Internet Gateway
RESULT=$(aws ec2 create-route \
  --route-table-id $ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID )
echo "  Route to '0.0.0.0/0' via Internet Gateway ID '$IGW_ID' ADDED to" \
  "Route Table ID '$ROUTE_TABLE_ID'."
 
# Associate Public Subnet with Route Table
RESULT=$(aws ec2 associate-route-table  \
  --subnet-id $SUBNET_PUBLIC_ID \
  --route-table-id $ROUTE_TABLE_ID )
echo "  Public Subnet ID '$SUBNET_PUBLIC_ID' ASSOCIATED with Route Table ID" \
  "'$ROUTE_TABLE_ID'."
 
# Enable Auto-assign Public IP on Public Subnet
aws ec2 modify-subnet-attribute \
  --subnet-id $SUBNET_PUBLIC_ID \
  --map-public-ip-on-launch 
 
echo " 'Auto-assign Public IP' ENABLED on Public Subnet ID" $SUBNET_PUBLIC_ID
 
# Creation clé SSH
aws_ssh_key_gen $KEY_NAME"_"$ENV_JENK
aws_ssh_key_gen $KEY_NAME"_"$ENV_DEV
aws_ssh_key_gen $KEY_NAME"_"$ENV_TEST
aws_ssh_key_gen $KEY_NAME"_"$ENV_PROD
aws_ssh_key_gen $KEY_NAME"_"$ENV_NEXUS
 
 
echo "Clés SSH crées et prêtes a être utilisées"
 
# Création du groupe de sécurité
GROUP_ID=$(aws ec2 create-security-group \
    --group-name SSHAccess \
    --query 'GroupId' \
    --description "Security group for SSH access" \
    --vpc-id $VPC_ID\
    --output text )
echo "Le groupe de sécurité a bien été créé avec l'id "$GROUP_ID
 
# Ajout des règles pour la connexion SSH
 
aws_set_tcp $GROUP_ID 22
aws_set_tcp $GROUP_ID 80
aws_set_tcp $GROUP_ID 8080
aws_set_tcp $GROUP_ID 8081
aws_set_tcp $GROUP_ID 5000
echo 'Les règles de sécurité ont été ajoutées'
 
# Lancer l'instance EC2

echo "Creation des Instances"
INSTANCE_ID_JENKINS=$(aws_create_EC2 $ENV_JENK install-jenkins-ansible.sh)
echo "L'instance $ENV_JENK est créée avec l'ID $INSTANCE_ID_JENKINS"
INSTANCE_ID_DEV=$(aws_create_EC2 "$ENV_DEV")
echo "L'instance $ENV_DEV est créée avec l'ID $INSTANCE_ID_DEV"
INSTANCE_ID_PROD=$(aws_create_EC2 $ENV_PROD)
echo "L'instance $ENV_PROD est créée avec l'ID $INSTANCE_ID_PROD"
INSTANCE_ID_TEST=$(aws_create_EC2 $ENV_TEST)
echo "L'instance $ENV_TEST est créée avec l'ID $INSTANCE_ID_TEST"
INSTANCE_ID_NEXUS=$(aws_create_EC2 $ENV_NEXUS install-nexus.sh)
echo "L'instance $ENV_NEXUS est créée avec l'ID $INSTANCE_ID_NEXUS"
 
#Allocation des IP Elastic
ELASTIC_IP_JENKINS=$(aws ec2 allocate-address | sudo jq '.PublicIp' | sed -e 's/^"//' -e 's/"$//')
ELASTIC_IP_PROD=$(aws ec2 allocate-address | sudo jq '.PublicIp' | sed -e 's/^"//' -e 's/"$//')
ELASTIC_IP_TEST=$(aws ec2 allocate-address | sudo jq '.PublicIp' | sed -e 's/^"//' -e 's/"$//')
ELASTIC_IP_DEV=$(aws ec2 allocate-address | sudo jq '.PublicIp' | sed -e 's/^"//' -e 's/"$//')
ELASTIC_IP_NEXUS=$(aws ec2 allocate-address | sudo jq '.PublicIp' | sed -e 's/^"//' -e 's/"$//')

echo "Waiting for EC2 start ..."
sleep 30

#Associate IP Elastic to EC2 instance
aws ec2 associate-address --instance-id $INSTANCE_ID_JENKINS --public-ip $ELASTIC_IP_JENKINS
aws ec2 associate-address --instance-id $INSTANCE_ID_DEV --public-ip $ELASTIC_IP_DEV
aws ec2 associate-address --instance-id $INSTANCE_ID_PROD --public-ip $ELASTIC_IP_PROD
aws ec2 associate-address --instance-id $INSTANCE_ID_TEST --public-ip $ELASTIC_IP_TEST
aws ec2 associate-address --instance-id $INSTANCE_ID_NEXUS --public-ip $ELASTIC_IP_NEXUS


#Ajout fingerprint de la connexion SSH, ne demande pas la permission par la suite
echo "Ajout des fingerprint Jenkins & Nexus"
ssh-keyscan -H $ELASTIC_IP_JENKINS >> ~/.ssh/known_hosts 
ssh-keyscan -H $ELASTIC_IP_NEXUS >> ~/.ssh/known_hosts 


#Préparation prérequis Ansible
#Copy SSH key (dev, prod & test) to Jenkins instance
echo "Copi Files to Jenkins Server ..."
echo "Copie des SSH KEY vers le Serveur Jenkins"
scp -i $KEY_NAME"_"$ENV_JENK".pem" ./$KEY_NAME"_"$ENV_DEV".pem" ubuntu@$ELASTIC_IP_JENKINS:/home/ubuntu/.ssh  
scp -i $KEY_NAME"_"$ENV_JENK".pem" ./$KEY_NAME"_"$ENV_PROD".pem" ubuntu@$ELASTIC_IP_JENKINS:/home/ubuntu/.ssh
scp -i $KEY_NAME"_"$ENV_JENK".pem" ./$KEY_NAME"_"$ENV_TEST".pem" ubuntu@$ELASTIC_IP_JENKINS:/home/ubuntu/.ssh
scp -i $KEY_NAME"_"$ENV_JENK".pem" ./$KEY_NAME"_"$ENV_NEXUS".pem" ubuntu@$ELASTIC_IP_JENKINS:/home/ubuntu/.ssh

#Create targets machine using data of générated item (IP, ssh key,user)
echo "Génération du fichier Host Invetor For Ansible"
echo "[appli]
dev ansible_host=$ELASTIC_IP_DEV ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/.ssh/"$KEY_NAME"_"$ENV_DEV".pem
test ansible_host=$ELASTIC_IP_TEST ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/.ssh/"$KEY_NAME"_"$ENV_TEST".pem
prod ansible_host=$ELASTIC_IP_PROD ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/.ssh/"$KEY_NAME"_"$ENV_PROD".pem
[depot]
nexus ansible_host=$ELASTIC_IP_NEXUS ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/.ssh/"$KEY_NAME"_"$ENV_NEXUS".pem
[all:vars]
ansible_python_interpreter=/usr/bin/python3">machines.txt

#copy the file to ~
echo "Copie file Ansible (inventory & Playbook) to jenkins/~"
scp -i $KEY_NAME"_"$ENV_JENK".pem" ./machines.txt ubuntu@$ELASTIC_IP_JENKINS:/home/ubuntu
scp -i $KEY_NAME"_"$ENV_JENK".pem" ./Appli-playbook.yml ubuntu@$ELASTIC_IP_JENKINS:/home/ubuntu

#Ajout fingerprint de la connexion SSH sur la machine Jenkins (usage pour ansible)
echo "Ajout des fingerprint Env_Dev to Jenkins"
ssh -i $KEY_NAME"_"$ENV_JENK".pem" ubuntu@$ELASTIC_IP_JENKINS "ssh-keyscan -H $ELASTIC_IP_DEV >> ~/.ssh/known_hosts" 
ssh -i $KEY_NAME"_"$ENV_JENK".pem" ubuntu@$ELASTIC_IP_JENKINS "ssh-keyscan -H $ELASTIC_IP_PROD >> ~/.ssh/known_hosts" 
ssh -i $KEY_NAME"_"$ENV_JENK".pem" ubuntu@$ELASTIC_IP_JENKINS "ssh-keyscan -H $ELASTIC_IP_TEST >> ~/.ssh/known_hosts"


#generation fichier infra (données relatifs aux composants créé)
echo "VPC_ID:$VPC_ID
SUBNET_PUBLIC_ID:$SUBNET_PUBLIC_ID
SUBNET_PRIVATE_ID:$SUBNET_PRIVATE_ID
GATEWAY_ID:$IGW_ID
ROUTE_TABLE_ID:$ROUTE_TABLE_ID
SECURITY_GROUP_ID:$GROUP_ID
INSTANCE_ID_JENKINS:$INSTANCE_ID_JENKINS
IP_JENKINS:$ELASTIC_IP_JENKINS
INSTANCE_ID_NEXUS:$INSTANCE_ID_NEXUS
IP_NEXUS:$ELASTIC_IP_NEXUS
INSTANCE_ID_DEV:$INSTANCE_ID_DEV
IP_DEV:$ELASTIC_IP_DEV
INSTANCE_ID_TEST:$INSTANCE_ID_TEST
IP_TEST:$ELASTIC_IP_TEST
INSTANCE_ID_PROD:$INSTANCE_ID_PROD
IP_PROD:$ELASTIC_IP_PROD" > infra_ID.txt



echo "File Infra.txt generated"

# check and copy keys
if [ ! -d "./keys" ]
then
	mkdir keys
fi
mv *.pem keys/

# 3 boucle while l'install Ansible, Jenkins & nexus not finished il fait un sleep de 5sec
echo "Getting Jenkins Password ..."
JENKINS_KEY=""
while [ "$JENKINS_KEY" == "" ]
do
    sleep 5
    JENKINS_KEY=$(ssh -i ./keys/$KEY_NAME"_"$ENV_JENK".pem" ubuntu@$ELASTIC_IP_JENKINS 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword' 2> /dev/null)
done
echo "Jenkins URL : http://$ELASTIC_IP_JENKINS:8080"
echo "Jenkins admin password ==> $JENKINS_KEY "
NEXUS_KEY=""

echo "Getting Nexus Password ..."
while [ "$NEXUS_KEY" == "" ]
do
    sleep 5
    NEXUS_KEY=$(ssh -i ./keys/$KEY_NAME"_"$ENV_NEXUS".pem" ubuntu@$ELASTIC_IP_NEXUS 'sudo cat /opt/nexus/sonatype-work/nexus3/admin.password' 2> /dev/null)
done
echo "Nexus URL : http://$ELASTIC_IP_NEXUS:8081"
echo "Nexus admin password ==> $NEXUS_KEY "

echo "Getting Ansible ready ..."
whichAnsible=""
while [ "$whichAnsible" == "" ]
do
    sleep 5
    whichAnsible=$(ssh -i ./keys/$KEY_NAME"_"$ENV_JENK".pem" ubuntu@$ELASTIC_IP_JENKINS 'which ansible-playbook')
done
# run playbook ansible
echo "Playing PlayBook Ansible"
ansiblepb=$(ssh -i ./keys/$KEY_NAME"_"$ENV_JENK".pem" ubuntu@$ELASTIC_IP_JENKINS 'ansible-playbook -i /home/ubuntu/machines.txt /home/ubuntu/Appli-playbook.yml')
echo $ansiblepb > pb.txt

# Affichage du resultat final d'ansible
val=$(cat pb.txt)
IFS=':' read -ra ADDR <<< $val
len=${#ADDR[@]}-1
# ${myVar##*( )} retire les blanc au debut 
echo ${ADDR[$len]##*( )}


INSTANCE_ID_MySQL_DEV=$(aws_create_RDS "$ENV_MySQL")


#aws rds modify-db-instance --db-instance-identifier "$rdsInstID" --db-parameter-group-name myParamGrp

 aws_create_RDS(){
         NAME=$KEY_NAME"_"DEV
#         NAME=$KEY_NAME"_"$1
#         if [ "$#" -eq 2 ]
#         then
                 File=$2
		 rdsInstID=rds-mysql-inst01
                 ID=$(aws rds create-db-instance \
                      	--db-instance-identifier $rdsInstID \
      			--allocated-storage 5 \
			--db-instance-class db.t2.medium \
		        --no-multi-az \
		        --no-auto-minor-version-upgrade \
 		        --availability-zone eu-west-3 \
			--vpc-security-group-ids  $GROUP_ID \
		        --db-subnet-group-name \
		        --engine mysql \
		        --port 3306 \
		        --master-username admin \
		        --master-user-password admin \
		        --db-parameter-group-name \
		        --db-name projet_devops_2021_DEV \
		        --backup-retention-period 3


#                         --user-data file://$File | sudo jq '.Instances[0].InstanceId' | sed -e 's/^"//' -e 's/"$//' )
#
#         else
#                 ID=$(aws ec2 run-instances \
#                         --instance-type t2.medium \
#                         --key-name $NAME \
#                         --security-group-ids $GROUP_ID \
#                         --subnet-id $SUBNET_PUBLIC_ID | sudo jq '.Instances[0].InstanceId' | sed -e 's/^"//' -e 's/"$//' )
#         fi
         aws rds create-tags --resources $ID --tags Key=Name,Value="GRP1_RDS_$1"
   echo $ID


