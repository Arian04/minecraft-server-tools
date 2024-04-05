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

# All the "foo || return" are there to make it so that if any script fails, this script returns early with its exit code.
main() {
	# Check that all required env vars are set (doesn't currently check if they're valid though)
	verify_env_var_existence || return

	# directory storing all the scripts below that will be called
	BIN=${MC_BIN_DIR}

	"$BIN/ensure-important-file-existence.sh" || return

	# Run preparation script
	"$BIN/prepare.py" || return

	# Run actual server start script
	echo "Starting server..."
	exec "$BIN/server-start.sh"
}

main "$@"
