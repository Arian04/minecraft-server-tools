#!/bin/bash

# Edit these variables
mc_dir="/home/arian/minecraft-servers"

server_name="zombie"
mc_version="1.12.2"
world_name="world"
rcon_port=27666

# Don't edit unless necessary
rcon_password=$(cat $mc_dir/rcon-keys/$server_name-key)

cd $(dirname $0)

# Hourly backup of origins minecraft server
/home/arian/bin/minecraft-backup -c -i "$mc_dir/$mc_version-$server_name-server/$world_name" -o /mnt/minecraft-servers-backup/$mc_version-$server_name-server -s localhost:$rcon_port:$rcon_password -w rcon
