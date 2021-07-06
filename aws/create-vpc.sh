#!/bin/bash
# creation d'un VPC AWS en CLI
aws ec2 create-vpc --cidr-block 10.10.0.0/16

# creation de 2 subnet
# vpc-xxxxxxxx pour l'id du vpc créer
aws ec2 create-subnet --vpc-id vpc-xxxxxxxxx --cidr-block 10.10.1.0/24
aws ec2 create-subnet --vpc-id vpc-xxxxxxxxx --cidr-block 10.10.2.0/24

# creation d'une Gateway internet
aws ec2 create-internet-gateway

# rattachement de l'internet Gateway au VPC
# igw-xxxxxxxx pour l'id de la gateway internet créée 
aws ec2 attach-internet-gateway --vpc-id vpc-xxxxxxxx --internet-gateway-id igw-yyyyyyyyyy
