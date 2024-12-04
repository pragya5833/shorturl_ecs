#!/bin/bash
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config


# Enable verbose logging for debugging
exec > >(tee /var/log/user-data.log | logger -t user-data ) 2>&1
yum install -y python3-pip
pip3 install botocore

# Install NFS client
sudo yum install -y amazon-efs-utils

# Create temporary mount directory
echo "Creating temporary mount directory for EFS..."
sudo mkdir -p /mnt/efs-temp

# Retry mounting EFS root
MAX_RETRIES=5
RETRY_DELAY=10

echo "Mounting EFS root to temporary directory..."
for ((i=1; i<=MAX_RETRIES; i++)); do
    sudo mount -t efs -o tls "${efs_file_system_id}":/ /mnt/efs-temp && break
    echo "EFS mount failed. Retrying in $RETRY_DELAY seconds... ($i/$MAX_RETRIES)"
    sleep $RETRY_DELAY
done

if [ "$i" -gt "$MAX_RETRIES" ]; then
    echo "Failed to mount EFS after $MAX_RETRIES attempts. Exiting."
    exit 1
fi

# Create the target subdirectory
echo "Creating target directory '/postgres-data' on EFS..."
sudo mkdir -p /mnt/efs-temp/postgres-data

# Unmount temporary mount
echo "Unmounting temporary mount..."
sudo umount /mnt/efs-temp

# Mount EFS at the desired location
echo "Mounting '/postgres-data' from EFS to /mnt/efs..."
sudo mkdir -p /mnt/efs
sudo mount -t efs -o tls "${efs_file_system_id}":/postgres-data /mnt/efs || { echo "Failed to remount EFS. Exiting."; exit 1; }

# Ensure the EFS mount persists across reboots
echo "Adding mount entry to /etc/fstab..."
sudo grep -q "${efs_file_system_id}:/postgres-data /mnt/efs" /etc/fstab || echo "${efs_file_system_id}:/postgres-data /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab

echo "EFS setup completed successfully."

# Format and mount the EBS volume
if [ ! -d /mnt/ebs/postgres ]; then
  mkfs -t ext4 /dev/xvdf
  mkdir -p /mnt/ebs/postgres
  mount /dev/xvdf /mnt/ebs/postgres
  chmod 777 /mnt/ebs/postgres
fi

# # Ensure the volume is mounted on reboot
echo "/dev/xvdf /mnt/ebs/postgres ext4 defaults,nofail 0 2" >> /etc/fstab
