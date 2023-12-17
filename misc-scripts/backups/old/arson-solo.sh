#!/bin/bash

# Server backup script, meant to run hourly as a cronjob.

# EDIT THE FOLLOWING VALUES

mc_dir="/home/arian/minecraft-servers/servers/casey-server" # Directory containing target server and rcon-keys directories

server_name="arson-solo"			# The name that comes after the version number of the server directory
rcon_port=25575

# DO NOT EDIT BELOW THIS LINE

# Adds /home/arian/bin to PATH, because the mcrcon binary is stored there
# mcrcon commands won't run in a cronjob without this
PATH="$PATH:/home/arian/bin"

export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

rcon_password=$(cat $mc_dir/rcon-keys/$server_name-key)

cd "$(dirname "$0")" || exit

# Disable saving on server to avoid files changing during backup
mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "save-off"

# Backs up server to borg repo
borg create --progress --verbose /mnt/minecraft-servers-backup/borg-$server_name-server::$server_name-server-"$(date +"%Y-%m-%d_%H:%M")" 	\
	$mc_dir/$server_name 2> /tmp/borg-mc-script-error

# Stores exit code of previous command, in this case, borg create
result=$?

# For debugging purposes
echo "Borg create exited with code: $result"

if [ $result -eq 0 ]; then
	# Alerts server that the backup has been successfully completed
	mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "tellraw @a [\"\",{\"text\":\"[Backup] \",\"color\":\"green\"},\"Complete!\"]"
else
	# Alerts server that the backup has failed
	error=$(cat /tmp/borg-mc-script-error)
	mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "tellraw @a [\"\",{\"text\":\"[Backup] \",\"color\":\"red\"},\"Failed. Exit code: $result.\"]"
	mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "say Error:${error}"
fi

# Re-enables saving after the backup has complete
mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "save-on"

# Saves the world to disk for good measure
mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "save-all"
