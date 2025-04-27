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

def create_table_if_not_exists(cursor):
    cursor.execute("""
	CREATE TABLE IF NOT EXISTS traffic_data (
		callsign VARCHAR(10),
		number VARCHAR(10),
		icao24 VARCHAR(10),
		registration VARCHAR(20),
		typecode VARCHAR(10),
		origin VARCHAR(10),
		destination VARCHAR(10),
		firstseen TIMESTAMP,
		lastseen TIMESTAMP,
		day DATE,
		latitude_1 DECIMAL(10,8),
		longitude_1 DECIMAL(11,8),
		altitude_1 FLOAT,
		latitude_2 DECIMAL(10,8),
		longitude_2 DECIMAL(11,8),
		altitude_2 FLOAT
	);
    """)

def create_summary_table_if_not_exists(cursor):
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS traffic_summary (
            id INT PRIMARY KEY,
            row_count INT,
            last_transponder_seen_at TIMESTAMP,
            most_popular_destination VARCHAR(10),
            count_of_unique_transponders INT
        );
    """)

def handle_s3_event(event):
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    file_key = event['Records'][0]['s3']['object']['key']
    
    # Download file from S3
    local_file_path = '/tmp/' + file_key

    s3_client.download_file(bucket_name, file_key, local_file_path)
    print("Downloaded file.")
    
    # Connect to RDS
    connection = pymysql.connect(host=rds_host, user=db_username, password=db_password, db=db_name)
    cursor = connection.cursor()
    print("Connected to RDS.")

    # Ensure the tables exist
    create_table_if_not_exists(cursor)
    create_summary_table_if_not_exists(cursor)
    print("Tables checked or created.")
    
    # Read CSV file and insert into RDS
    batch = []
    batch_size = 500

    with gzip.open(local_file_path, 'rt') as f_in:
        csv_reader = csv.reader(f_in)
        headers = next(csv_reader)

        for row in csv_reader:
            batch.append(row)
            if len(batch) >= batch_size:
                cursor.executemany("""
                    INSERT INTO traffic_data (
                        callsign, number, icao24, registration, typecode, origin, destination,
                        firstseen, lastseen, day, latitude_1, longitude_1, altitude_1, latitude_2, longitude_2, altitude_2
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, batch)
                connection.commit()
                batch.clear()

        # Insert any remaining rows
        if batch:
            cursor.executemany("""
                INSERT INTO traffic_data (
                    callsign, number, icao24, registration, typecode, origin, destination,
                    firstseen, lastseen, day, latitude_1, longitude_1, altitude_1, latitude_2, longitude_2, altitude_2
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, batch)
            connection.commit()

    print("Inserted all rows into traffic_data.")

    # Generate and save summary data
    cursor.execute("SELECT COUNT(*) FROM traffic_data")
    row_count = cursor.fetchone()[0]

    cursor.execute("SELECT MAX(lastseen) FROM traffic_data")
    last_transponder_seen_at = cursor.fetchone()[0]

    cursor.execute("""
        SELECT destination, COUNT(*) as count
        FROM traffic_data
        WHERE destination IS NOT NULL AND destination != ''
        GROUP BY destination
        ORDER BY count DESC
        LIMIT 1
    """)
    most_popular_destination = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(DISTINCT icao24) FROM traffic_data")
    count_of_unique_transponders = cursor.fetchone()[0]

    cursor.execute("""
        INSERT INTO traffic_summary (id, row_count, last_transponder_seen_at, most_popular_destination, count_of_unique_transponders)
        VALUES (1, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            row_count = VALUES(row_count),
            last_transponder_seen_at = VALUES(last_transponder_seen_at),
            most_popular_destination = VALUES(most_popular_destination),
            count_of_unique_transponders = VALUES(count_of_unique_transponders)
    """, (
        row_count,
        last_transponder_seen_at,
        most_popular_destination,
        count_of_unique_transponders
    ))

    connection.commit()
    cursor.close()
    connection.close()

    print("Saved summary to traffic_summary.")

    return {
        'statusCode': 200,
        'body': json.dumps('File ingested successfully and summary updated.')
    }
    
def handle_api_request(event):
    print("Handling API request...")

    connection = pymysql.connect(host=rds_host, user=db_username, password=db_password, db=db_name)
    cursor = connection.cursor(pymysql.cursors.DictCursor)

    cursor.execute("SELECT * FROM traffic_summary WHERE id = 1")
    summary = cursor.fetchone()

    cursor.close()
    connection.close()

    if summary:
        return {
            'statusCode': 200,
            'body': json.dumps(summary, default=str)
        }
    else:
        return {
            'statusCode': 404,
            'body': json.dumps({'message': 'Summary not found'})
        }