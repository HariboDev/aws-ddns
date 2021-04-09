#!/bin/bash

## Check if running script as root or sudo
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run as root or sudo"
  exit
fi


## Checking which version of Python is installed
## Will use Python3 if both are present
## Will exit if no Python versions are present
PYTHON2=false
PYTHON3=false

if ls /usr/bin/python2* 1> /dev/null 2>&1; then
  PYTHON2=true
fi

if ls /usr/bin/python3* 1> /dev/null 2>&1; then
  PYTHON3=true
fi

if [[ !($PYTHON2) && !($PYTHON3) ]]; then
  echo "Python is not installed. Exiting..."
  exit
fi

if [[ $PYTHON2 && !($PYTHON3) ]]; then
  sed -i "s/ExecStart=/usr/bin/python3 /usr/local/sbin/aws-ddns.py/ExecStart=/usr/bin/python /usr/local/sbin/aws-ddns.py/" aws-ddns.service
fi


## Installs python script dependencies using pip
echo "Installing dependencies..."
if [[ $PYTHON3 ]]; then
  pip3 install boto3
else
  pip install boto3
fi


## Change file permissions
echo "Updating file permissions"
chmod 777 aws-ddns.service
chmod 777 aws-ddns.py
chmod 777 aws-ddns.json


## Retrieves current public IP address, desired DNS record
## properties and AWS credentials and saves to aws-ddns.json
function get_int() {
  read -p "$1: " INT_INPUT
  if [[ $INT_INPUT =~ ^[0-9]+$ && "$INT_INPUT" -gt "0" ]]; then
    echo $INT_INPUT
  else
    echo $(get_int "$1")
  fi
}

CURRENT_IP=$(curl ipinfo.io/ip)
echo
read -p "Route53 Hosted Zone ID: " HOSTED_ZONE_ID
read -p "DNS record name [e.g. test.example.com]: " RECORD_NAME
RECORD_TTL=$(get_int "TTL for DNS record (secs)")

function save_data_with_keys() {
  read -p "AWS Access Key: " AWS_ACCESS_KEY
  read -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
  echo "{ \"ip\": \"${CURRENT_IP}\", \"hosted_zone_id\": \"$HOSTED_ZONE_ID\", \"record_name\": \"$RECORD_NAME\", \"record_ttl\": $RECORD_TTL, \"aws_access_key\": \"$AWS_ACCESS_KEY\", \"aws_secret_access_key\": \"$AWS_SECRET_ACCESS_KEY\", \"first_time\": true }" > aws-ddns.json
}

while true; do
  read -p "Is this an EC2 instance? (y/n): " RESPONSE
  case $RESPONSE in
    [Yy]* )
      while true; do
        read -p "Is the required role attached? (y/n): " RESPONSE2
        case $RESPONSE2 in
          [Yy]* )
            echo "{ \"ip\": \"${CURRENT_IP}\", \"hosted_zone_id\": \"$HOSTED_ZONE_ID\", \"record_name\": \"$RECORD_NAME\", \"record_ttl\": $RECORD_TTL, \"first_time\": true }" > aws-ddns.json
          break;;
          [Nn]* )
            save_data_with_keys
          break;;
        esac
      done
    break;;
    [Nn]* )
      save_data_with_keys
    break;;
  esac
done


## Retrieves desired checking interval and saves to aws-ddns.service using unix Stream Editor (sed)
SERVICE_INTERVAL=$(get_int "Service interval (secs)")
sed -i "s/RestartSec=.*/RestartSec=$SERVICE_INTERVAL/" aws-ddns.service


## Copies service python and json files to relevent their locations
echo "Copying files to relevent directories"
cp ./aws-ddns.service /etc/systemd/system/aws-ddns.service
cp ./aws-ddns.py /usr/local/sbin/aws-ddns.py
cp ./aws-ddns.json /usr/local/sbin/aws-ddns.json


## Reloads systemd manager configuration for new service
systemctl daemon-reload


## Checks if user wishes to have service launch on boot and executes relevent command
while true; do
  read -p "Auto-start on boot? (y/n): " RESPONSE
  case $RESPONSE in
    [Yy]* )
      systemctl enable aws-ddns.service;
    break;;
    [Nn]* )
    break;;
  esac
done


## Starts the service
echo "Starting service..."
systemctl start aws-ddns.service

echo "Successfully installed!"
echo