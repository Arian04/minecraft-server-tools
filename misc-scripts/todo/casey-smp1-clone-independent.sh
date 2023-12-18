#!/bin/bash

# Server clone script, clones server so it can be independently manipulated.
# Useful for testing without impacting main server

# Meant to be temporary, so it doeesn't dynamically choose ports and
# disables bungeecord

# Will likely be inaccessible due to firewall rules until manually permitted

# EDIT THE FOLLOWING VALUES

mc_dir="/home/arian/minecraft-servers/casey-server" # Directory containing target server and rcon-keys directories

server_name="smp1"			# The name that comes after the version number of the server directory
rcon_port=39110

# Updated values for cloned server
new_local_port=49110
new_rcon_port=59110
new_server_name=$server_name-clone-temp

# Adds /home/arian/bin to PATH, because the mcrcon binary is stored there
# mcrcon commands won't run in a cronjob without this
PATH="$PATH:/home/arian/bin"

# DO NOT EDIT BELOW THIS LINE
rcon_password=$(cat $mc_dir/rcon-keys/$server_name-key)

cd "$(dirname "$0")" || exit

# Disable saving on server to avoid files changing during clone
mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "save-off"

# Saves the world to disk to make sure files are up to date
mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "save-all"

# Clones server (note trailing / on source to only rsync contents of dir and not dir itself)
rsync -avhPHAX $mc_dir/$server_name-server/ $mc_dir/$new_server_name-server 2> /tmp/clone-mc-script-error

# Stores exit code of previous command
result=$?

if [ $result -eq 0 ]; then
	# Alerts server that the cloning has been successfully completed
	mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "tellraw @a [\"\",{\"text\":\"[Clone] \",\"color\":\"green\"},\"Complete!\"]"

	# Update server connection port
	sed -i "s/server-port=.*/server-port=$new_local_port/" $mc_dir/$new_server_name-server/server.properties

	# Update server rcon port
	sed -i "s/rcon.port=.*/rcon.port=$new_rcon_port/" $mc_dir/$new_server_name-server/server.properties

	# Update start.sh
	sed -i "s:mc_dir=.*:mc_dir=$mc_dir/$new_server_name-server:" $mc_dir/$new_server_name-server/start.sh
	sed -i "s/local_port=.*/local_port=$new_local_port/" $mc_dir/$new_server_name-server/start.sh
	sed -i "s/server_name=.*/server_name=$new_server_name/" $mc_dir/$new_server_name-server/start.sh

	# Disable velocity and enable online-mode since it won't be behind a proxy
	python3 /home/arian/minecraft-servers/other-scripts/disable-velocity.py "$mc_dir/$new_server_name-server/paper.yml"
	sed -i "s/online-mode=.*/online-mode=true/" $mc_dir/$new_server_name-server/server.properties
else
	# Alerts server that the cloning has failed
	error=$(cat /tmp/clone-mc-script-error)
	mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "tellraw @a [\"\",{\"text\":\"[Clone] \",\"color\":\"red\"},\"Failed. Exit code: $result.\"]"
	mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "mail send carl_markss Error: $error"
fi

# Re-enables saving after the clone has complete
mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "save-on"

# Saves the world to disk for good measure
mcrcon -P "$rcon_port" -H localhost -p "$rcon_password" "save-all"

