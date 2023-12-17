#!/bin/bash

# Server backup script, meant to run periodically as a cronjob.
# Disables saving on the server, creates a borg archive, then re-enables saving and broadcasts an anouncement to the server

# Instructions:
# 	Create the borg repository before using the script like this:
# 	borg init --encryption=none /mnt/minecraft-servers-backup/borg-$server_name-server
# 	Then add the script to crontab

# EDIT THE FOLLOWING VALUES

mc_dir="/home/arian/minecraft-servers"
server_name="mavis-smp"	# The name that comes after the version number of the server directory
rcon_port="25566"

# DO NOT EDIT BELOW THIS LINE

# Adds /home/arian/bin to PATH, because the mcrcon binary is stored there
# mcrcon commands won't run in a cronjob without this
PATH="$PATH:/home/arian/bin"

export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

rcon_password="$(cat $mc_dir/rcon-keys/${server_name}_rcon-key.txt)"

cd "$(dirname "$0")" || exit

run_rcon_command() {
	command="$1"
	mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "${command}"
}

# If RCON port is listening (aka server is up)
nc -z localhost $rcon_port
nc_result=$?
if [ $nc_result != 0 ]; then
	echo "Exiting because server isn't running"
	exit 1
fi

# Notifies server that backup is starting
run_rcon_command 'tellraw @a ["","[Backup] ","Starting..."]'

# Disable saving on server to avoid files changing during backup
run_rcon_command "save-off"

# Backs up server to borg repo
borg create --progress --verbose \
/mnt/minecraft-servers-backup/borg-$server_name-server::$server_name-server-"$(date +"%Y-%m-%d_%H:%M")" 	\
	$mc_dir/servers/${server_name}_server 2> /tmp/borg-mc-script-error

# Stores exit code of previous command, in this case, borg create
result=$?

# For debugging purposes
echo "Borg create exited with code: $result"

if [ $result -eq 0 ]; then
	# Alerts server that the backup has been successfully completed
	run_rcon_command 'tellraw @a ["","[Backup] ",{"text":"Complete!","color":"green"}]'
else
	# Alerts server that the backup has failed
	error=$(cat /tmp/borg-mc-script-error)
	run_rcon_command "tellraw @a [\"\",\"[Backup] \",{\"text\":\"Failed. Exit code: $result.\",\"color\":\"red\"}]"

	# Essentials plugin (or another plugin with a mail command) required
	run_rcon_command "mail send carl_markss Error: $error"
fi

# Re-enables saving after the backup has complete
run_rcon_command "save-on"

# Saves the world to disk for good measure
run_rcon_command "save-all"
