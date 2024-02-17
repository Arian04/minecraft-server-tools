#!/bin/sh

# Server backup script, meant to run periodically as a cronjob.
# - disables saving on the server
# - creates a borg archive
# - re-enables saving
# - broadcasts an announcement to the server

error() {
	echo >&2 "ERROR:" "$@"
}
info() {
	echo "INFO:" "$@"
}

run_rcon_cmd() {
	command="$1"
	${RCON_CMD} -P "$RCON_PORT" -H "$RCON_TARGET" -p "$RCON_PASSWORD" "${command}"
}

check_for_problems() {
	# Check that data directory exists
	if [ ! -e ${SERVER_DIR} ]; then
		error "server data directory (${SERVER_DIR}) doesn't exist"
		return 1
	fi

	# Check that data directory is non-empty
	# shellcheck disable=SC2010 # I'm just checking for emptiness, so the normal cons don't apply
	if ! ls -A "${SERVER_DIR}" | grep -q '^'; then
		error "server data directory (${SERVER_DIR}) is empty"
		return 1
	fi

	# Check if rcon client binary is accessible
	if ! command -v ${RCON_CMD} >/dev/null 2>&1; then
		error "rcon client binary could not be found"
		return 1
	fi

	# Check if RCON port is listening (aka server is up)
	nc -z "$RCON_TARGET" "$RCON_PORT"
	nc_result=$?
	if [ $nc_result != 0 ]; then
		error "server's RCON port isn't responding." \
			"Is the server running?" \
			"Is RCON enabled?" \
			"Is the firewall configured correctly?"
		return 1
	fi
}

find_rcon_password() {
	# TODO: check that this errors out properly if rcon.password is missing or empty (is empty valid?)
	sed -n 's/^rcon.password=\(.*$\)/\1/p' "${SERVER_DIR}/server.properties" || {
		error "failed to get RCON password"
		return 1
	}
}

init_borg_repo() {
	borg init --encryption=none "${BORG_REPO}"
}

main() {
	: "${RCON_PORT:=25575}"
	: "${RCON_TARGET:=localhost}"

	# set misc vars
	SERVER_DIR="/data"
	RCON_CMD="mcrcon"
	TIME="$(date +"%Y-%m-%d_%H:%M")"

	# set borg vars
	BORG_REPO="/backups/borg-minecraft-server"
	BORG_ARCHIVE_NAME="${TIME}"
	export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
	export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

	# exit early if issues are found
	check_for_problems || return $?

	# get RCON password a little late because I want to check for problems beforehand
	RCON_PASSWORD="$(find_rcon_password)" || return $?

	# init borg repo if it doesnt exist
	if [ ! -e ${BORG_REPO} ]; then
		info "Borg repo doesn't exist. Creating it..."
		init_borg_repo || return $?
	fi

	# Notifies server that backup is starting
	run_rcon_cmd 'tellraw @a ["","[Backup] ","Starting..."]'

	# Disable the server writing changes to disk to avoid files changing during backup
	run_rcon_cmd "save-off"

	# Backs up server to borg repo
	# TODO: see how --progress looks in logs and maybe remove it
	borg create --progress ${BORG_REPO}::"${BORG_ARCHIVE_NAME}" "${SERVER_DIR}"

	# $? stores the exit code of the previous command, in this case, borg create
	borg_result=$?
	if [ $borg_result = 0 ]; then
		# Alerts server that the backup has been successfully completed
		run_rcon_cmd 'tellraw @a ["","[Backup] ",{"text":"Complete!","color":"green"}]'
	else
		# Alerts server that the backup has failed
		run_rcon_cmd "tellraw @a [\"\",\"[Backup] \",{\"text\":\"Failed. Exit code: $borg_result.\",\"color\":\"red\"}]"

		# NOTE: Essentials plugin (or another plugin with a mail command) required
		# run_rcon_cmd "mail send your_username_here Error: $BORG_ERROR"
	fi

	# Re-enables saving after the backup has complete
	run_rcon_cmd "save-on"

	# Flush changes in the world to disk for good measure
	run_rcon_cmd "save-all"
}

main "$@"
