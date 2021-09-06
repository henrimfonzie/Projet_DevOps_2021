#!/usr/bin/env bash
 
apt-get update
 
# install python
apt-get install python3 python3-dev python3-pip -q -y
apt remove -y python 
 
mv /usr/bin/python3 /usr/bin/python