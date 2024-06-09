#!/bin/bash

#Install required packages
if ! command -v upzip &> /dev/null; then
    echo "Installing upzip..."
    sudo apt install unzip
fi

# Install uplink CLI if not already installed
if ! command -v uplink &> /dev/null; then
    echo "Installing uplink CLI..."
    curl -L https://github.com/storj/storj/releases/latest/download/uplink_linux_amd64.zip -o uplink_linux_amd64.zip
    unzip -o uplink_linux_amd64.zip
    sudo install uplink /usr/local/bin/uplink
fi

# Storj setup (run only once)
if [ ! -f "/root/.local/share/storj/uplink/config.yaml" ]; then
    echo "Setting up uplink CLI..."
    uplink access create --import-as "main" --satellite-address "YOUR_SATELLITE_URL" --api-key "YOUR_API_KEY" --passphrase-stdin <<< "YOUR_PASSPHRASE"
fi

# Define variables
DIR_TO_BACKUP="/root/ceremonyclient/node/.config"
VPS_IP=$(hostname -I | awk '{print $1}')
STORJ_BUCKET="qnode-$VPS_IP"

# Check if the bucket already exists
if ! uplink ls | grep -q "sj://$STORJ_BUCKET"; then
    # Bucket does not exist, create it
    echo "Creating a new bucket..."
    uplink mb "sj://$STORJ_BUCKET"
fi

# Define backup file name with date and time
BACKUP_FILE="backup_$(TZ=Asia/Seoul date +%Y%m%d_%H%M).tar.gz"

# Create a tar.gz file of the directory you want to backup and upload to Storj
echo "Creating tar file of $DIR_TO_BACKUP and uploading to Storj..."
tar -czf "/tmp/$BACKUP_FILE" -C "$(dirname "$DIR_TO_BACKUP")" "$(basename "$DIR_TO_BACKUP")"
uplink cp /tmp/$BACKUP_FILE sj://$STORJ_BUCKET/$BACKUP_FILE

echo "Backup script execution completed."

# Remove the backup file from /tmp
echo "Removing backup file from /tmp..."
rm -f "/tmp/$BACKUP_FILE"

echo "Backup script execution completed."

# Function to set up cron job
setup_cron_job() {
    local schedule=$1
    local script_path=$2

    # Remove existing cron job for the script
    crontab -l | grep -v "$script_path" | crontab -

    # Add new cron job
    (crontab -l; echo "$schedule $script_path") | crontab -
    echo "Cron job added to run at: $schedule"
}

# Check if this is the first time the script is run (if the cron job is not already set)
if ! crontab -l | grep -q "/root/Q_backup.sh"; then
    # Prompt the user for backup interval
    echo "Enter backup interval in hours (e.g., '24' for every 24 hours):"
    read -r interval_hours

    # Convert interval to cron expression (run script every n hours)
    cron_schedule="0 */$interval_hours * * *"

    # Add the script to cron with the specified schedule
    setup_cron_job "$cron_schedule" "/root/Q_backup.sh"
    echo "Backup script scheduled to run every $interval_hours hours."
else
    # Get the current cron schedule
    current_schedule=$(crontab -l | grep "/root/Q_backup.sh" | awk '{print $1,$2,$3,$4,$5}')
    echo "Backup script already scheduled to run at $current_schedule."
fi


