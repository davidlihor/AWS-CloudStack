import json
import boto3
import os
from botocore.exceptions import ClientError

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

BUCKET_NAME = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    action = event.get('action')
    user_id = event.get('userId')
    task_id = event.get('taskId')
    
    print(f"[{action}] Processing cleanup for user={user_id}, task={task_id}")
    
    try:
        if action == 'delete_dynamodb':
            return delete_dynamodb(user_id, task_id)
        elif action == 'delete_s3':
            return delete_s3_objects(user_id, task_id)
        elif action == 'log_failure':
            return log_failure(event, context.aws_request_id)
        else:
            raise ValueError(f"Unknown action: {action}")
            
    except Exception as e:
        print(f"Error in {action}: {str(e)}")
        raise e

def delete_dynamodb(user_id, task_id):
    try:
        response = table.delete_item(
            Key={
                'userId': user_id,
                'taskId': task_id
            },
            ReturnValues='ALL_OLD'
        )
        
        deleted_item = response.get('Attributes', {})
        had_image = deleted_item.get('hasImage', False)
        
        print(f"DynamoDB delete success: task={task_id}, hadImage={had_image}")
        
        return {
            'statusCode': 200,
            'userId': user_id,
            'taskId': task_id,
            'action': 'delete_dynamodb',
            'hadImage': had_image,
            'deletedItem': deleted_item
        }
        
    except ClientError as e:
        print(f"DynamoDB delete failed: {e.response['Error']['Code']}")
        raise e

def delete_s3_objects(user_id, task_id):
    prefix = f"users/{user_id}/{task_id}/"
    files_to_delete = ['photo.png', 'thumbnail.png']
    deleted = []
    failed = []
    
    for filename in files_to_delete:
        key = f"{prefix}{filename}"
        try:
            s3.delete_object(Bucket=BUCKET_NAME, Key=key)
            deleted.append(key)
            print(f"S3 delete success: {key}")
        except ClientError as e:
            if e.response['Error']['Code'] == 'NoSuchKey':
                print(f"S3 object not found (skipping): {key}")
            else:
                print(f"S3 delete failed for {key}: {e.response['Error']['Code']}")
                failed.append({'key': key, 'error': e.response['Error']['Code']})
    
    if failed:
        raise Exception(f"Failed to delete {len(failed)} S3 objects: {failed}")
    
    return {
        'statusCode': 200,
        'userId': user_id,
        'taskId': task_id,
        'action': 'delete_s3',
        'deletedFiles': deleted
    }

def log_failure(event, aws_request_id=None):
    error = event.get('error', {})
    user_id = event.get('userId')
    task_id = event.get('taskId')
    
    failure_log = {
        'level': 'ERROR',
        'message': 'Task cleanup failed',
        'userId': user_id,
        'taskId': task_id,
        'error': error,
        'timestamp': aws_request_id or 'unknown'
    }
    
    print(json.dumps(failure_log))
    
    return {
        'statusCode': 500,
        'userId': user_id,
        'taskId': task_id,
        'action': 'log_failure',
        'error': error
    }
