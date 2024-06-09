# QUIL_daily_backup
This is a basic backup script for Quilibrium node after 1.4.19 update as .config/store folder gets also important for your reward

# Storj
I used Storj for backup cloud service, so using Uplink CLI for uploading backup files to Storj service.  
           https://www.storj.io/  
you may check more from above site.
If you know better cloud service, let me know.  
If you are willing to backup at your local, feel free to

# Backup Files
```.config``` folder will be backed up by this format -> ```backup_$(date +%Y%m%d_%H%M%S).tar.gz```
in your storj buckets, with buckets name with your ```vps_ip```

# Backup Scheduling (Setting Interval)
once you run the script, script will ask you to automate the script to run in certain interval(in time period)  
(e.g., '24' for backing up the .config folder every 24 hours)

# Removal of backups that are older than 10 days
To prevent your cloud getting full, the backed up file in your storj will be deleted for backups that are older than 10 days

# Usage
1. Download the Script
```
   wget https://raw.githubusercontent.com/legokinder/QUIL_daily_backup/main/Q_backup.sh
```
2. Run
```
   sudo nano ~/.Q_backup.sh
```
 then, replace ```YOUR_API_KEY```, ```YOUR_SATELLITE_URL```, ```YOUR_PASSPHRASE``` from your script  
 You may make your api key, passphrase in the storj website
 
 3. Make the Script Executable
```
   chmod +x Q_backup.sh
```
 4. Run the Script Manually
```
   ./Q_backup.sh
```




