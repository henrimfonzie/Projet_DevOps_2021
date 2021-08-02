

#Creation Security Group pour le RDS Database (MySQL)
#Group Name - dbSecGrp
#Description - My Database Security Group

dbSecGrpID=$(aws ec2 create-security-group \
           --group-name dbSecGrp \
           --description "Security Group for database servers" \
           --vpc-id "$vpcID" \
           --output text)


rdsInstID=rds-mysql-ID-groupe_1
aws rds create-db-instance \
        --db-instance-identifier "$rdsInstID" \
        --allocated-storage 5 \
        --db-instance-class db.t2.small \
        --no-multi-az \
        --no-auto-minor-version-upgrade \
        --availability-zone eu-west-3 \
        --vpc-security-group-ids ID-de-notre-VPC \
        --db-subnet-group-name "mysqldbsubnet" \
        --engine mysql \
        --port 3306 \
        --master-username admin \
        --master-user-password admin \
        --db-parameter-group-name \
        --db-name projet_devops_2021 \
        --backup-retention-period 3
        
#aws rds modify-db-instance --db-instance-identifier "$rdsInstID" --db-parameter-group-name myParamGrp
