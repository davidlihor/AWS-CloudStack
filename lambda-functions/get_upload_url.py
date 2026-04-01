import boto3
import os
import json
from botocore.config import Config

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])
s3_client = boto3.client('s3', config=Config(signature_version='s3v4'))

def lambda_handler(event, context):
    user_id = event['requestContext']['authorizer']['claims']['sub']
    
    body = json.loads(event.get('body', '{}'))
    task_id = body.get('taskId')
    file_ext = body.get('extension', 'png').replace('.', '')

    if not task_id:
        return {'statusCode': 400, 'body': json.dumps({'error': 'taskId is required'})}

    response = table.get_item(Key={
        'userId': user_id, 
        'taskId': task_id
    })

    if 'Item' not in response:
        return {
            'statusCode': 404,
            'headers': get_cors_headers(),
            'body': json.dumps({'error': 'Task not found or unauthorized'})
        }

    file_key = f"users/{user_id}/{task_id}/photo.{file_ext}"
    
    upload_url = s3_client.generate_presigned_url(
        ClientMethod='put_object',
        Params={
            'Bucket': os.environ['BUCKET_NAME'],
            'Key': file_key,
            'ContentType': f'image/{file_ext}'
        },
        ExpiresIn=300
    )

    return {
        "statusCode": 200,
        "headers": get_cors_headers(),
        "body": json.dumps({
            "uploadURL": upload_url,
            "imageKey": file_key
        })
    }

def get_cors_headers():
    return {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
    }
