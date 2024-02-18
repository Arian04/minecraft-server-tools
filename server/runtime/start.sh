#!/bin/sh

main() {
	# directory storing all the scripts below that will be called
	BIN=${MC_BIN_DIR:?}

	# Check that all required env vars are set (doesn't currently check if they're valid though)
	: "${JAR_NAME:?}"
	: "${MEMORY_AMOUNT:?}"

	# Run preparation script, if it returns an error, exit
	"$BIN/prepare.py"

	# Run actual server start script
	"$BIN/server-start.sh"
}

main "$@"
