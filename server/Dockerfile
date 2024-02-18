# syntax = docker/dockerfile:1

ARG BUILDER_IMAGE
ARG BUILDER_IMAGE_TAG
ARG RUNNER_IMAGE
ARG RUNNER_IMAGE_TAG

# TODO: lots of hardcoded paths, I wonder if there's a standard way that people handle that issue

##### Build #####
# uses my script to download the required jar file
FROM ${BUILDER_IMAGE}:${BUILDER_IMAGE_TAG} AS build

WORKDIR /build

ARG MC_JAR_TYPE
ARG MC_VERSION

COPY ./build/get-mc-jar .
RUN pip install --no-cache-dir -r ./requirements.txt
RUN ./get-mc-jar.py ${MC_JAR_TYPE} server.jar ${MC_VERSION}

##### Runtime #####
FROM ${RUNNER_IMAGE}:${RUNNER_IMAGE_TAG}

# udev - Minecraft warns when it isn't available. Not sure what actually happens if it's missing though.
# python3 - for running some of my scripts
RUN apk add --no-cache udev python3

# create non-root user and switch to it
ENV SERVICE_NAME="minecraft"
ENV UID=1001 GID=1001
RUN \
	addgroup -g ${GID} -S ${SERVICE_NAME}; \
	adduser -u ${UID} -G ${SERVICE_NAME} -s /bin/false -D -H -S ${SERVICE_NAME}
USER ${SERVICE_NAME}

# Copy over scripts
ENV MC_BIN_DIR="/mc-bin"
ENV PATH="${PATH}:${MC_BIN_DIR}"
WORKDIR ${MC_BIN_DIR}
COPY --chown=${SERVICE_NAME}:${SERVICE_NAME} --chmod=500 ./runtime/start.sh .
COPY --chown=${SERVICE_NAME}:${SERVICE_NAME} --chmod=500 ./runtime/prepare.py .
COPY --chown=${SERVICE_NAME}:${SERVICE_NAME} --chmod=500 ./runtime/server-start.sh .

WORKDIR /data
COPY --from=build --chown=${SERVICE_NAME}:${SERVICE_NAME} /build/server.jar .

VOLUME [ "/data" ]
VOLUME [ "/backups" ]

STOPSIGNAL SIGTERM
EXPOSE 25565

ENV JAR_NAME=server.jar MEMORY_AMOUNT="" EULA=""

ENTRYPOINT [ "/mc-bin/start.sh" ]

# TODO:set up healthcheck?
