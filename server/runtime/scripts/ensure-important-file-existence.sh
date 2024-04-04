#!/bin/sh

SRC=${GENERATED_DATA_DIR}
DEST=${SERVER_DATA_DIR}

# if file is missing in destination directory, copy it over
copy_if_missing() {
	FILENAME="${1}"

	if [ ! -e "$DEST/$FILENAME" ]; then
		echo "file doesnt exist in server data dir"

		cp "$SRC/$FILENAME" "$DEST"
		return 1
	fi

	return 0
}

# check if files are the same
file_is_equal() {
	SRC_FILE="$SRC/$FILENAME"
	DEST_FILE="$DEST/$FILENAME"

	# if files differ...
	if (! cmp --silent "$SRC_FILE" "$DEST_FILE"); then
		# TODO: is there anything else I should do in this situation other than warn?
		echo "$DEST_FILE has been modified externally, delete it if you want it to be re-created as default"

		return 1
	fi

	return 0
}

do_all_checks() {
	FILENAME="${1:?missing required arg}"

	# If any test "fails" then it ends early due to the continuous "&&" chain.
	# A "fail" really just means it found (and usually fixed) an issue.
	copy_if_missing "$FILENAME" &&
		file_is_equal "$FILENAME"
}

main() {
	do_all_checks "$JAR_NAME"

	# Not doing all checks for `server.properties`, because I'm gonna let the preparation script handle it.
	# Otherwise this would always just report that it doesn't match the default `server.properties`.
	copy_if_missing "server.properties"
}

main "$@"
