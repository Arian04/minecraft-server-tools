#!/bin/bash

# Edit these variables
mc_dir="/home/arian/minecraft-servers"

server_name="origins"
mc_version="1.16.5"
world_name="planned childhood V2"
rcon_port=27888

# Don't edit unless necessary
rcon_password=$(cat $mc_dir/rcon-keys/$server_name-key)

cd $(dirname $0)

# Hourly backup of origins minecraft server
/home/arian/bin/minecraft-backup -c -i "$mc_dir/$mc_version-$server_name-server/$world_name" -o /mnt/minecraft-servers-backup/$mc_version-$server_name-server -s localhost:$rcon_port:$rcon_password -w rcon
