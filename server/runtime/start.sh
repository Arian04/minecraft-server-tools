#!/bin/sh

# Minecraft server start script

# TODO: check for all required env vars
: "${JAR_NAME:?}"
: "${MEMORY_AMOUNT:?}"

# start server
# shellcheck disable=SC2086 # jvm_args word-splitting is intentional
#java "-Xms${MEMORY_AMOUNT}" "-Xmx${MEMORY_AMOUNT}" ${jvm_args} --add-modules=jdk.incubator.vector -jar "${JAR_NAME}" nogui
