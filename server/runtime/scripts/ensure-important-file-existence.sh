#!/bin/sh

SRC=${GENERATED_DATA_DIR}
DEST=${SERVER_DATA_DIR}

##### Misc Utility functions #####
# check if the file in the server data directory is the same as the default file that came with the container image
file_is_equal() {
	FILENAME="${1}"
	SRC_FILE="$SRC/$FILENAME"
	DEST_FILE="$DEST/$FILENAME"

	# if files differ...
	if (! cmp --silent "$SRC_FILE" "$DEST_FILE"); then
		return 1
	fi

	return 0
}

##### Higher level verification functions #####
# if file is missing in destination directory, copy it over
copy_if_missing() {
	FILENAME="${1}"
	SRC_FILE="$SRC/$FILENAME"
	DEST_FILE="$DEST/$FILENAME"

	if [ ! -e "$DEST_FILE" ]; then
		echo "$DEST_FILE doesnt exist in server data dir, copying the default file to that location."

		cp "$SRC_FILE" "$DEST"
		return 1
	fi

	return 0
}

warn_if_changed_externally() {
	FILENAME="${1}"
	DEST_FILE="$DEST/$FILENAME"

	if (! file_is_equal "$FILENAME"); then
		echo "$DEST_FILE has been modified externally, delete it if you want it to be re-created as default."

		return 1
	fi

	return 0

}

do_all_checks() {
	FILENAME="${1:?missing required arg}"

	# If any test "fails" then it ends early due to the continuous "&&" chain.
	# A "fail" really just means it found (and usually fixed) an issue.
	copy_if_missing "$FILENAME" &&
		warn_if_changed_externally "$FILENAME"
}

main() {
	# A little custom logic for the server jar so we can handle updates
	if [ "$MANAGE_SERVER_JAR" != "false" ]; then
		copy_if_missing "$JAR_NAME"
		file_is_equal "$JAR_NAME" || {
			echo "Server jar file is not the one expected to be used with this container image, replacing it. You can disable this behavior with MANAGE_SERVER_JAR=false"
			cp "$SRC/$FILENAME" "$DEST"
		}
	else
		echo "MANAGE_SERVER_JAR is set to false, so no checks are being performed on it. You're on your own if your server jar doesn't work properly."
	fi

	# Not doing all checks for `server.properties`, because I'm gonna let the preparation script handle it.
	# Otherwise this would always just report that it doesn't match the default `server.properties`.
	copy_if_missing "server.properties"
}

main "$@"
