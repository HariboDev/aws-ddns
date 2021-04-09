#!/bin/bash


## Check if running script as root or sudo
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run as root or sudo"
  exit
fi


## Stops, disables and deletes service
echo "Disabling service..."
systemctl disable aws-ddns.service

echo "Stopping service..."
systemctl stop aws-ddns.service

echo "Deleting service..."
rm /etc/systemd/system/aws-ddns.service


## Removes scripts and data files
echo "Deleting scripts and data..."
rm /usr/local/sbin/aws-ddns.py
rm /usr/local/sbin/aws-ddns.json

echo "Uninstalled!"
echo