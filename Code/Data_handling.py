#! /usr/bin/env python

# python script to handle big data through minio object storage
# Access MinIO files
from minio import Minio
import os
import glob
import time

# Configuration (do not containerize this cell)
param_minio_endpoint = "scruffy.lab.uvalight.net:9000"
param_minio_user_prefix = "zhanqing2016@gmail.com"  # Your personal folder in the naa-vre-user-data bucket in MinIO
secret_minio_access_key = "sFmE1jsm5hjJBBGh5RBL"
secret_minio_secret_key = "pczCG6FRpXQEtad7lAvXv00iCYFd5Dpa1g8GOWzR"

mc = Minio(endpoint=param_minio_endpoint,
           access_key=secret_minio_access_key,
           secret_key=secret_minio_secret_key)

# List existing buckets: get a list of all available buckets
mc.list_buckets()

# List files in bucket: get a list of files in a given bucket. For bucket `naa-vre-user-data`, only list files in your personal folder
local_data_dir = "/export/lv9/user/qzhan/TempSED/data"
minio_folder = "TempSED/Ricky_data"

# Get all files from local directory
all_files = glob.glob(os.path.join(local_data_dir, "*"))

# Upload all files to MinIO
print(f"Found {len(all_files)} files to upload")
print(f"Starting upload at {time.strftime('%Y-%m-%d %H:%M:%S')}")

for idx, file_path in enumerate(all_files, 1):
    if os.path.isfile(file_path):
        file_name = os.path.basename(file_path)
        file_size = os.path.getsize(file_path) / (1024 * 1024)  # Convert to MB
        object_name = f"{param_minio_user_prefix}/{minio_folder}/{file_name}"
        try:
            print(f"[{idx}/{len(all_files)}] Uploading {file_name} ({file_size:.2f} MB)...", end=" ", flush=True)
            mc.fput_object(bucket_name="naa-vre-user-data",
                           file_path=file_path,
                           object_name=object_name)
            print("✓ Done")
        except Exception as e:
            print(f"✗ Error: {e}")

print(f"Upload completed at {time.strftime('%Y-%m-%d %H:%M:%S')}")

# Download file from bucket: download `myfile.csv` from your personal folder on MinIO and save it locally as `myfile_downloaded.csv`
# mc.fget_object(bucket_name="naa-vre-user-data", object_name=f"{param_minio_user_prefix}/PCLake_PLoads.png", file_path="/export/lv9/user/qzhan/home/PCLake_PLoads.png")
