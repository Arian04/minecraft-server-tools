# syntax = docker/dockerfile:1

# image args
ARG BUILDER_IMAGE
ARG BUILDER_IMAGE_TAG
ARG RUNNER_IMAGE
ARG RUNNER_IMAGE_TAG

# constants
ARG GENERATED_DATA_DIR=/opt/minecraft
ARG SERVER_DATA_DIR=/data
ARG MC_BIN_DIR=/mc-bin
ARG JAR_NAME=server.jar

# TODO: lots of hardcoded paths, I wonder if there's a standard way that people handle that issue

##### Get jar file #####
# uses my script to download the required jar file
FROM ${BUILDER_IMAGE}:${BUILDER_IMAGE_TAG} AS builder_jar

WORKDIR /build

ARG MC_JAR_TYPE
ARG MC_VERSION
ARG JAR_NAME

COPY ./build/get-mc-jar .
RUN pip install --no-cache-dir -r ./requirements.txt
RUN ./get-mc-jar.py ${MC_JAR_TYPE} ${JAR_NAME} ${MC_VERSION}

##### Generate default config files #####
FROM ${RUNNER_IMAGE}:${RUNNER_IMAGE_TAG} as builder_config

WORKDIR /build

ARG EULA
ARG MEMORY_AMOUNT=1G
ARG JAR_NAME

COPY --from=builder_jar /build/${JAR_NAME} .

# Create eula file based on the arg that has been passed to the builder.
# There is no default, so this should be the same as a true acknowledgement of accepting the EULA.
RUN echo "eula=${EULA}" >> ./eula.txt

# Run minecraft server and immediately send "stop" to stdin, stopping the server ASAP
RUN echo stop | java "-Xmx${MEMORY_AMOUNT}" -jar "${JAR_NAME}"

##### Runtime #####
FROM ${RUNNER_IMAGE}:${RUNNER_IMAGE_TAG}

# udev - Minecraft warns when it isn't available. Not sure what actually happens if it's missing though.
# python3 - for running some of my scripts
RUN apk add --no-cache udev python3


# TODO: figure out how to un-hardcode this to work with UID/GID other than 1000
# create non-root user and switch to it
ENV SERVICE_NAME="minecraft"
ENV UID=1000 GID=1000
RUN \
	addgroup -g ${GID} -S ${SERVICE_NAME}; \
	adduser -u ${UID} -G ${SERVICE_NAME} -s /bin/false -D -H -S ${SERVICE_NAME}
USER ${SERVICE_NAME}

# Copy over scripts to custom directory and add to PATH
ARG MC_BIN_DIR
ENV PATH="${PATH}:${MC_BIN_DIR}"
WORKDIR ${MC_BIN_DIR}
COPY --chown=${SERVICE_NAME}:${SERVICE_NAME} --chmod=500 ./runtime/* .

ARG GENERATED_DATA_DIR
ARG JAR_NAME
WORKDIR ${GENERATED_DATA_DIR}
COPY --from=builder_jar --chown=${SERVICE_NAME}:${SERVICE_NAME} /build/${JAR_NAME} .
COPY --from=builder_config --chown=${SERVICE_NAME}:${SERVICE_NAME} /build/server.properties .

ARG SERVER_DATA_DIR
VOLUME ${SERVER_DATA_DIR}
VOLUME [ "/backups" ]

# No real purpose for this, but it seems reasonable
WORKDIR ${SERVER_DATA_DIR}

STOPSIGNAL SIGTERM

# MC and RCON ports respectively
EXPOSE 25565
EXPOSE 25575

# Expose some environment variables for use in the container

# For internal use
ENV \
	JAR_NAME=${JAR_NAME} \
	SERVER_DATA_DIR=${SERVER_DATA_DIR} \
	MC_BIN_DIR=${MC_BIN_DIR} \
	GENERATED_DATA_DIR=${GENERATED_DATA_DIR}

# For users to override
ENV MEMORY_AMOUNT="" EULA=""

# substituting $MC_BIN_DIR into here causes too many problems, so just remember to manually update
# this if $MC_BIN_DIR ever changes
ENTRYPOINT [ "/mc-bin/start.sh" ]

# TODO:set up healthcheck?
