# Terraform script for EC2 instance change logging
Terraform script for logging user and instance details in an AWS account on who started/stopped an EC2 instance. Logs are kept in an S3 bucket.

The script creates AWS CloudTrail trail and EventBridge rule to capture any EC2 Instance start/stop activities. Once an API comes into the CloudTrail, Cloudwatch rule will trigger a Lambda function and forward the details to the function. The Lambda function receives the data, retrieves the necessary details and write the information into an S3 file.

### Versions
`Terraform v0.14.7` <br>
`Python v3.8` <br>

# Running the script

## Configure Variables
Before running the script, make sure the variables are configured as required. All the variables are kept in the file `variables.tf`.

## Set Credentials
Before running the script, make sure you have set the credentials for an AWS account. You can set the credentials in environment variables as shown below:
```bash
    $ export AWS_ACCESS_KEY_ID="anaccesskey"
    $ export AWS_SECRET_ACCESS_KEY="asecretkey"
```

## Terraform init
Initialise the Terraform providers and packages using `terraform init` command.

## Terraform apply
Run the script using `terraform apply` command. Input `yes` when prompted for confirmation.
