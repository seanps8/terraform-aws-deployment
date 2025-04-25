import json
import boto3
import pymysql
import os
import gzip
import csv

s3_client = boto3.client('s3')
rds_host = os.environ['RDS_HOST']
db_username = os.environ['DB_USERNAME']
db_password = os.environ['DB_PASSWORD']
db_name = os.environ['DB_NAME']

def lambda_handler(event, context):
    if 'Records' in event and event['Records'][0]['eventSource'] == 'aws:s3':
        return handle_s3_event(event)
    else:
        return handle_api_request(event)

def handle_s3_event(event):
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    file_key = event['Records'][0]['s3']['object']['key']
    
    # Download file from S3
    local_file_path = '/tmp/' + file_key
    s3_client.download_file(bucket_name, file_key, local_file_path)
    
    # Decompress the .gz file
    decompressed_file_path = local_file_path.replace('.gz', '')
    with gzip.open(local_file_path, 'rb') as f_in:
        with open(decompressed_file_path, 'wb') as f_out:
            f_out.write(f_in.read())
    
    # Connect to RDS
    connection = pymysql.connect(host=rds_host, user=db_username, password=db_password, db=db_name)
    cursor = connection.cursor()
    
    # Read CSV file and insert into RDS
    with open(decompressed_file_path, 'r') as file:
        csv_reader = csv.reader(file)
        headers = next(csv_reader)  # Skip the header row
        for row in csv_reader:
            cursor.execute("INSERT INTO your_table_name (column1, column2, column3) VALUES (%s, %s, %s)", row)
    
    connection.commit()
    cursor.close()
    connection.close()
    
    return {
        'statusCode': 200,
        'body': json.dumps('File ingested successfully')
    }

def handle_api_request(event):
    # Connect to RDS
    connection = pymysql.connect(host=rds_host, user=db_username, password=db_password, db=db_name)
    cursor = connection.cursor()
    
    # Query data
    cursor.execute("SELECT COUNT(*) FROM your_table_name")
    row_count = cursor.fetchone()[0]
    
    cursor.execute("SELECT * FROM your_table_name LIMIT 10")
    rows = cursor.fetchall()
    
    cursor.close()
    connection.close()
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'row_count': row_count,
            'sample_data': rows
        })
    }