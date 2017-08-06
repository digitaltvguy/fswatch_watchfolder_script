# fswatch_watchfolder_script
shell script for fswatch which checks watchfolder for new files via event type flags and delivers via scp to destination

**MOST IMPORTANT - IT WATCHES FOR FILES THAT ARE COPYING AND ONLY SENDS A TRIGGER WHEN THE FILE COPY IS COMPLETED**

**CURRENTLY FILTERS FOR MOV AND MXF VIDEO FILES**

** I'M WORKING ON MAKING THE TRIGGERS INCLUDE FILTER WORK VIA A VARIABLE THAT CAN BE SET **

This script uses file system events to check a watchfolder and transfers the file to a remote server

It looks for to fswatch event names "Updated" and "Renamed" so files don't trigger until ready.

"Renamed" event accepts file moves into the watch folder

"Updated" accepts a “file-closed” event after a file copy into the watch
folder occurs

If a file is removed from the watch folder, the script checks for this
false event by examining the folder for the same file.  If it doesn’t exist,
the event is ignored.


***** MUST CONFIGURE LINES WITHIN CONFIGURATION SECTION ******
