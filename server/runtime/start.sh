#!/bin/sh

verify_env_var_existence() {
	# internal env vars
	: "${JAR_NAME:?}"
	: "${MC_BIN_DIR:?}"
	: "${SERVER_DATA_DIR:?}"
	: "${GENERATED_DATA_DIR:?}"

	# user-facing env vars
	: "${EULA:?}"
	: "${MEMORY_AMOUNT:?}"
}

main() {
	# Check that all required env vars are set (doesn't currently check if they're valid though)
	verify_env_var_existence

	# directory storing all the scripts below that will be called
	BIN=${MC_BIN_DIR}

	"$BIN/ensure-important-file-existence.sh"

	# Run preparation script, if it returns an error, exit
	"$BIN/prepare.py"

	# Run actual server start script
	exec "$BIN/server-start.sh"
}

main "$@"
