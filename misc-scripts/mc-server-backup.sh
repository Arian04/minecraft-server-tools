#!/bin/sh

# Server backup script, meant to run periodically as a cronjob.
# Disables saving on the server, creates a borg archive, then re-enables saving and broadcasts an announcement to the server

# Instructions:
# 	Create the borg repository before using the script like this:
# 	borg init --encryption=none /mnt/minecraft-servers-backup/borg-$server_name-server
# 	Then add the script to crontab

run_rcon_cmd() {
	command="$1"
	mcrcon -P "$rcon_port" -H "$rcon_target" -p "$RCON_PASSWORD" "${command}"
}

check_for_problems() {
  # Check if rcon client binary is accessible
  if ! command -v mcrcon /dev/null 2>&1; then
    echo "ERROR: rcon client binary could not be found"
    return 1
  fi

  # Check if RCON port is listening (aka server is up)
  nc -z "$rcon_target" "$rcon_port"
  nc_result=$?
  if [ $nc_result != 0 ]; then
    echo "ERROR: server's RCON port isn't responding, is it running?"
    return 1
  fi
}

main() {
  # old hardcoded input:
  #   server_name="enigmatica-2"
  #   rcon_port="25571"
  # get user input
  readonly server_name=${1?}	# The name of the server directory
  readonly rcon_port=${2?}
  readonly rcon_target=${3="localhost"}
  readonly mc_dir=${4="/home/arian/minecraft-servers/"}

  # set misc vars
  PATH="$PATH:/home/arian/bin" # rcon client binary is stored here
  TIME="$(date +"%Y-%m-%d_%H:%M")"
  RCON_PASSWORD="$(cat ${mc_dir}/rcon-keys/${server_name}_rcon-key.txt)"
  SERVER_DIR="${mc_dir}/servers/${server_name}_server"
  TMP_ERROR_DIR="/tmp/mc-server-${server_name}"
  TMP_ERROR_FILE="${TMP_ERROR_DIR}/mc-backup-script-error_${TIME}"

  # set borg vars
  BORG_REPO="/mnt/minecraft-servers-backup/borg-${server_name}-server"
  BORG_ARCHIVE_NAME="${server_name}-server-${TIME}"
  export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
  export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

  # exit early if issues are found
  check_for_problems
  result=$?
  if [ $result != 0 ]; then
    return $result
  fi

  cd "$(dirname "$0")" || { echo "ERROR: failed to cd to script directory"; return 1; }

  # Notifies server that backup is starting
  run_rcon_cmd 'tellraw @a ["","[Backup] ","Starting..."]'

  # Disable the server writing changes to disk to avoid files changing during backup
  run_rcon_cmd "save-off"

  # Backs up server to borg repo
  borg create --progress --verbose ${BORG_REPO}::"${BORG_ARCHIVE_NAME}" \
     ${SERVER_DIR} \
    --exclude ${SERVER_DIR}/backups \
    2> "${TMP_ERROR_FILE}"

  # Stores exit code of previous command, in this case, borg create
  borg_result=$?

  # For debugging purposes
  # echo "'borg create' exited with code: $borg_result"

  if [ $borg_result = 0 ]; then
    # Alerts server that the backup has been successfully completed
    run_rcon_cmd 'tellraw @a ["","[Backup] ",{"text":"Complete!","color":"green"}]'
  else
    error=$(cat /tmp/borg-mc-script-error)

    # Alerts server that the backup has failed
    run_rcon_cmd "tellraw @a [\"\",\"[Backup] \",{\"text\":\"Failed. Exit code: $borg_result.\",\"color\":\"red\"}]"

    # NOTE: Essentials plugin (or another plugin with a mail command) required
    run_rcon_cmd "mail send carl_markss Error: $error"
  fi

  # Re-enables saving after the backup has complete
  run_rcon_cmd "save-on"

  # Flush changes in the world to disk for good measure
  run_rcon_cmd "save-all"
}

main "$@"