import json
import boto3
import botocore
from requests import get

data_file_path = "/usr/local/sbin/aws-ddns.json"


## Updates the Route53 record value to be the new public IP address of the server
def update_route53(data):
    try:
        client = boto3.client(
          "route53",
          aws_access_key_id=data["aws_access_key"],
          aws_secret_access_key=data["aws_secret_access_key"]
        )
        client.change_resource_record_sets(
            HostedZoneId=data["hosted_zone_id"],
            ChangeBatch={
                "Comment": "Automatic DNS update",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": data["record_name"],
                            "Type": "A",
                            "TTL": data["record_ttl"],
                            "ResourceRecords": [
                                {"Value": data["ip"]},
                            ],
                        },
                    },
                ],
            },
        )
    except botocore.exceptions.NoCredentialsError:
      found_credentials = True

      if "aws_access_key" not in data:
        found_credentials = False
        print("Unable to locate AWS Access Key. Try running setup.sh again.")

      if "aws_secret_access_key" not in data:
        found_credentials = False
        print("Unable to locate AWS Secret Access Key. Try running setup.sh again.")

      if not found_credentials:
        return

    except Exception as e:
        print("Unable to update Route53 record")
        print(e)
        return
    
    update_local_data_store(data)


## Updates the local aws-ddns.json file to contain the new public IP address
def update_local_data_store(data):
    try:
        file = open(data_file_path, "w")
    except:
        print("Unable to locate aws-ddns.json")
    else:
        data["first_time"] = False

        try:
            file.write(json.dumps(data))
            file.close()
            print("Updated old IP")
        except Exception as e:
            print(e)


## Reads aws-ddns.json file and gets current public IP
## address and compares the two to check for a change
def main():
    old_ip = ""

    try:
        file = open(data_file_path, "r")
        data = json.loads(file.read())
        file.close()
        old_ip = data["ip"]
    except FileNotFoundError:
        print("Data file not found. Run the setup.sh script first.")
    else:
        if old_ip != "":
            try:
                current_ip = get("https://api.ipify.org").text

                if current_ip != old_ip:
                    print("IP change detected")
                    data["ip"] = current_ip
                    update_route53(data)
                elif data["first_time"]:
                    print("First time run")
                    update_route53(data)
                else:
                    print("No IP change detected")

            except:
                print("Unable to retrieve public IP address")


if __name__ == "__main__":
    main()
