#!/bin/bash

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
    uplink setup --api-key "YOUR_API_KEY" --satellite "YOUR_SATELLITE_URL" --passphrase "YOUR_PASSPHRASE"
fi

# Define variables
BACKUP_DIR="/root/backup"
DIR_TO_BACKUP="/root/ceremonyclient/node/.config"
VPS_IP=$(hostname -I | awk '{print $1}')
STORJ_BUCKET="$VPS_IP"

# Define backup file name with date and time
BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create a tar.gz file of the directory you want to backup
echo "Creating tar file of $DIR_TO_BACKUP..."
tar -czf "$BACKUP_DIR/$BACKUP_FILE" -C "$(dirname "$DIR_TO_BACKUP")" "$(basename "$DIR_TO_BACKUP")"

# Upload the backup file to Storj
echo "Uploading $BACKUP_FILE to Storj..."
uplink cp "$BACKUP_DIR/$BACKUP_FILE" "sj://$STORJ_BUCKET/$BACKUP_FILE"

# Remove backups older than 10 days from the local backup directory
echo "Removing local backups older than 10 days..."
find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +10 -exec rm -f {} \;

# Optionally, remove backups older than 10 days from Storj
OLD_DATE=$(date --date="10 days ago" +%Y%m%d)
echo "Removing Storj backups older than 10 days..."
uplink rm "sj://$STORJ_BUCKET/backup_$OLD_DATE*.tar.gz"

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
fi

