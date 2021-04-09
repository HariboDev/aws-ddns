# AWS DDNS

A linux service to periodically check for public IP address changes. Updates Route53 DNS record using Python and AWS's Python SDK library: boto3. Pretty much a dynamic DNS solution.

Compatible with:

:heavy_check_mark: EC2 instances

:heavy_check_mark: On-premise servers

## Requirements
- Linux
  - Python 2.x or Python 3.x with binary in `/usr/bin/`
  - Pip or Pip3 with binary in `/usr/bin/`
  - Sudo privileges
- AWS
  - If using EC2:
    - Role attached with permissions to update Route53
    - See below for a recommended IAM policy
  - If using on-premise
    - Access key and secret access key with permissions to update Route53
    - See below for a recommended IAM policy

## Permissions
Below is a recommended IAM policy for the EC2 role or IAM user. This policy follows the AWS Best Practice for permissions with least privilege.
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowRoute53RecordUpdate",
            "Effect": "Allow",
            "Action": "route53:ChangeResourceRecordSets",
            "Resource": "arn:aws:route53:::hostedzone/HOSTED_ZONE_ID"
        }
    ]
}
```

## Installation
```bash
## Clone the git repository and move into it
git clone https://github.com/HariboDev/aws-ddns.git
cd aws-ddns

## Change the permissions on the setup script to allow for execution
sudo chmod +x ./setup.sh

## Execute the script
## You must be sudo or root
sudo ./setup.sh
```
The `setup.sh` script:
  - Checks if currently running as sudo or root
  - Attempts to locate the Python binaries for Python2.x or Python3.x
  - Prefers Python3.x if possible
  - Installs dependencies
  - Changes the file permissions
  - Asks for the following:
    - Route53 Hosted Zone Id
    - DNS record name
    - DNS record TTL (must be int && > 0)
    - If running on EC2 && no role attached:
      - AWS Access Key
      - AWS Secret Access Key
    - Service interval time (must be int && > 0)
  - Retrieves the current IP address of the server
  - Populates the `aws-ddns.json` data file
  - Moves the serivce, python script and data files to relevent directories
  - Reloads the system manager configuration using `systemctl daemon-reload`
  - Asks if you want to load the service on server boot:
    - If so, enables the service using `systemctl enable aws-ddns.service`
  - Starts the service using `systemctl start aws-ddns.service`

## Usage
When the service is running, the Python interpreter is used to:
  - Check for a change in the server's public IP
  - Attempts to update the Route53 DNS record
  - Updates `aws-dns.json` data file to hold the new public IP address

## Uninstallation
```bash
## Move into the directory of the repository
cd aws-ddns

## Change the permissions on the script to allow for execution
sudo chmod +x ./uninstall.sh

## Execute the script
## You must be sudo or root
sudo ./uninstall.sh
```
The `uninstall.sh`:
  - Disables the service
  - Stops the service
  - Deletes the service files
  - Deletes the python script and data files
