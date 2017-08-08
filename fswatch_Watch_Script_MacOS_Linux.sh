#! /bin/bash

# ********************************************************
# FSWATCH-based Watchfolder script optimized for Media File movement
#
# Chris Seeger     August 8th, 2017
#
# ********************************************************


# ********************************************************
# CONFIGURE START
# ********************************************************
# ********************************************************
#           REMINDERS
# 1. Add Arcfour256 to sshd_config file
# 2. Add public key from your source machine to destination server to avoid authentication request for scp copy
# 3. Add config file to /etc/newssyslog.d folder (fswatch_watchfolder.conf) to manage logs
# 4. Set file system extension variable.  This will filter file system events
#
# ********************************************************


# identify location of fswatch and ssh binaries
FSWATCH_PATH="/usr/local/bin/fswatch"
sshPath="/usr/bin/ssh"
rsyncPath="/usr/bin/rsync"

# Redirect Log location ***REMEMBER*** TO CREATE the file fswatch_watchfolder.log file
# and set permissions appropriately so that the script service can write to it 
LOG_FILE_PATH="<path to log file>"    
exec >> "$LOG_FILE_PATH"
exec 2>&1


# identify local location of Watchfolder
LOCAL_WATCHFOLDER_PATH="<local filesystem watchfolder path>"

# Choose cipher to use for SSH (choices best choices arcfour256, aes256-ctr, aes128-ctr)
SSH_cipher="aes128-ctr"

# File Extensions to filter with fswatch (ie- 'mov|mxf|tif') always separate with a pipe "|"
FileExtensionFilter='mov|mxf'

# Set Finished File Folder Path
TARGET_TRANSITION_PATH="<target path>"
# Set remote path if using remote destination
REMOTE_DESTINATION_PATH="<user@IP:remote path>"

# Amount of time that passes between the moment fswatch outputs a set of detected changes
# and the next. What happens in-between events is a monitor-specific detail
#
LATENCY=3

# ********************************************************
# CONFIGURE END
# ********************************************************
#
# ***DO NOT MODIFY BELOW THIS LINE****
#
# ***DO NOT MODIFY BELOW THIS LINE****
#
# ********************************************************

FilterExpression=".*\.("$FileExtensionFilter")$"
echo "$FilterExpression"

# Watch for changes and sync (exclude hidden files)
echo    "Watching for changes. Quit anytime with Ctrl-C."
${FSWATCH_PATH} -0 \
	-e ".*" \
	-IEi "$FilterExpression" \
	--exclude="/\.[^/]*$" \
	--event Updated --event Renamed --event MovedTo -l $LATENCY \
	$LOCAL_WATCHFOLDER_PATH \
| while read -d "" event
  do
# Create Unique temp file name  
    TempFileName="/tmp/fswatch_temp_file_`date +"%m-%d-%Y_%H-%M-%S"`"
#   echo "$TempFileName"
    echo $event > "$TempFileName"
#    echo -en "${green}" `date '+%m-%d-%Y_%H:%M:%S'` "${nocolor}\"$event\" changed."
#	 echo "Synchronizing... "
#    echo ""
#    echo \"$event\"

# Get specific columns seperated by zeros
#awk '{print $1 " "$2 " "$3 " " $4 " " $5}' /tmp/fswatch_temp_file

# Store trigger file path in variable
TriggerFilePath="`cat $TempFileName`"
echo "$TriggerFilePath"

# Get base name of Trigger File
TriggerFileBaseName=`echo "$TriggerFilePath" | sed 's/.*\///'`

# Test variables
# echo "$TriggerFilePath"
# cat "$TempFileName"

# Wait for files to be moved
sleep 1

#Check for false tripper because of file being moved out of the watchfolder to destination
if [ -f "$TriggerFilePath" ]
	then
echo ""
echo "$TriggerFilePath File exists in watchfolder"
echo "Moving file to Transition Folder"
mv "$TriggerFilePath" "$TARGET_TRANSITION_PATH"
#echo "$TriggerFileBaseName"
TransitionFilePathSource="${TARGET_TRANSITION_PATH}${TriggerFileBaseName}"

# Copy file(s) using faster arcfour256 cipher - This for this cipher must be added to sshd config file
# A public ssh key needs to be set up to avoid authentication requests from scp
echo "Copying "$TriggerFileBaseName" to Destination Server"
	$rsyncPath -aW \
	--size-only \
    --include-from="$TempFileName" \
    --stats \
    -e "$sshPath -T -c "$SSH_cipher" -o Compression=no -x" \
    "$TransitionFilePathSource" "$REMOTE_DESTINATION_PATH" \
    | tee -a "$LOG_FILE_PATH"
	else
echo ""
#echo "$TriggerFilePath File has been removed from watchfolder"
fi

sleep 2

# Removing temp event file and looping to next event
 rm "$TempFileName"


done