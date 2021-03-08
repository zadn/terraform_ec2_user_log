import json
import boto3
import datetime

def lambda_handler(event, context):
    event_name = event['detail']['eventName']

    bucket_name = "ec2-invoke-logs"
    file_name = "EC2_" + event_name + "_" + str(datetime.datetime.now()) + '.txt'
    lambda_path = "/tmp/" + file_name
    s3_path = file_name

    instance_details = str(event['detail']['responseElements']['instancesSet'])
    user_details = str(event['detail']['userIdentity'])
    event_time = str(event['detail']['eventTime'])

    file_body = 'Instance Action : ' + event_name + '\n'
    file_body += 'Instance Details : ' + instance_details + '\n\n'
    file_body += 'User Details : ' + user_details + '\n\n'
    file_body += 'Event Time : ' + event_time

    encoded_string = file_body.encode("utf-8")

    s3 = boto3.resource("s3")
    s3.Bucket(bucket_name).put_object(Key=s3_path, Body=encoded_string)

    return {
        'statusCode': 200,
        'body': json.dumps('Event details stored to S3' )
    }
