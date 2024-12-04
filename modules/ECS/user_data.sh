#!/bin/bash
set -xeuo pipefail

# Enable verbose logging for debugging
exec > >(tee /var/log/user-data.log | logger -t user-data ) 2>&1

echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config

# Wait for network connectivity
echo "Checking network connectivity..."
MAX_RETRIES=20
RETRY_DELAY=5

for ((i=1; i<=MAX_RETRIES; i++)); do
    if curl -sSf https://aws.amazon.com >/dev/null; then
        echo "Network is up!"
        break
    else
        echo "Network is not ready. Retrying in $${RETRY_DELAY} seconds... ($${i}/$${MAX_RETRIES})"
        sleep $${RETRY_DELAY}
    fi
done

if [ "$${i}" -gt "$${MAX_RETRIES}" ]; then
    echo "Network is still not available after $${MAX_RETRIES} attempts. Exiting."
    exit 1
fi

# Install EFS utilities and botocore
echo "Installing amazon-efs-utils and botocore..."
yum install -y amazon-efs-utils python3-pip
pip3 install botocore

# Create temporary mount directory
TEMP_DIR="/mnt/efs-temp"
FINAL_DIR="/mnt/efs"

echo "Creating temporary mount directory: $${TEMP_DIR}"
mkdir -p "$${TEMP_DIR}"

# Set EFS_ID
EFS_ID="${efs_file_system_id}"
echo "EFS_ID is set to: $${EFS_ID}"

# Retry mounting EFS root
MAX_RETRIES=5
RETRY_DELAY=10

echo "Mounting EFS root to temporary directory..."
for ((i=1; i<=MAX_RETRIES; i++)); do
    mount -t efs -o tls "$${EFS_ID}":/ "$${TEMP_DIR}" && break
    echo "EFS mount failed. Retrying in $${RETRY_DELAY} seconds... ($${i}/$${MAX_RETRIES})"
    sleep $${RETRY_DELAY}
done

if [ "$${i}" -gt "$${MAX_RETRIES}" ]; then
    echo "Failed to mount EFS after $${MAX_RETRIES} attempts. Exiting."
    exit 1
fi

# Create the target subdirectory
POSTGRES_DIR="$${TEMP_DIR}/postgres-data"
echo "Creating target directory: $${POSTGRES_DIR}"
mkdir -p "$${POSTGRES_DIR}"

# Unmount temporary mount
echo "Unmounting temporary mount..."
umount "$${TEMP_DIR}"

# Mount EFS at the desired location
echo "Mounting '/postgres-data' from EFS to $${FINAL_DIR}..."
mkdir -p "$${FINAL_DIR}"
mount -t efs -o tls "$${EFS_ID}":/postgres-data "$${FINAL_DIR}" || { echo "Failed to remount EFS to $${FINAL_DIR}. Exiting."; exit 1; }

# Ensure the EFS mount persists across reboots
echo "Adding mount entry to /etc/fstab..."
grep -q "$${EFS_ID}:/postgres-data $${FINAL_DIR}" /etc/fstab || echo "$${EFS_ID}:/postgres-data $${FINAL_DIR} efs defaults,_netdev 0 0" >> /etc/fstab

echo "EFS setup completed successfully."
