#!/bin/bash

# Server backup script, meant to run periodically as a cronjob.
# Disables saving on the server, creates a borg archive, then re-enables saving and broadcasts an anouncement to the server

# Instructions:
# 	Create the borg repository before using the script like this:
# 	borg init --encryption=none /mnt/minecraft-servers-backup/borg-$server_name-server
# 	Then add the script to crontab

# EDIT THE FOLLOWING VALUES

mc_dir="/home/arian/minecraft-servers"
server_name="mavis-smp-120"	# The name of the server directory
rcon_port="25566"

# DO NOT EDIT BELOW THIS LINE

# Adds /home/arian/bin to PATH, because the mcrcon binary is stored there
# mcrcon commands won't run in a cronjob without this
PATH="$PATH:/home/arian/bin"

export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

rcon_password="$(cat $mc_dir/rcon-keys/${server_name}_rcon-key.txt)"

cd "$(dirname "$0")" || exit

# Disable saving on server to avoid files changing during backup
mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "save-off"

# Backs up server to borg repo
borg create --progress --verbose /mnt/minecraft-servers-backup/borg-$server_name-server::$server_name-server-"$(date +"%Y-%m-%d_%H:%M")" 	\
	$mc_dir/servers/$server_name-server 2> /tmp/borg-mc-script-error

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

	# Essentials plugin (or another plugin with a mail command) required
	mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "mail send carl_markss Error: $error"
fi

# Re-enables saving after the backup has complete
mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "save-on"

# Saves the world to disk for good measure
mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "save-all"
