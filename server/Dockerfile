# syntax = docker/dockerfile:1

ARG BUILDER_IMAGE
ARG BUILDER_IMAGE_TAG
ARG RUNNER_IMAGE
ARG RUNNER_IMAGE_TAG

ARG MC_JAR_TYPE
ARG MC_VERSION

# TODO: lots of hardcoded paths, I wonder if there's a standard way that people handle that issue

##### Build #####
# uses my script to download the required jar file
FROM ${BUILDER_IMAGE}:${BUILDER_IMAGE_TAG} AS build

WORKDIR /build

COPY ./misc-scripts/get-mc-jar .
RUN pip install --no-cache-dir -r ./requirements.txt
RUN ./get-mc-jar.py ${MC_JAR_TYPE} server.jar ${MC_VERSION}

##### Runtime #####
FROM ${RUNNER_IMAGE}:${RUNNER_IMAGE_TAG}

# Minecraft warns when udev isn't available. Not sure what actually happens if it's missing though.
RUN apk add --no-cache udev

# create non-root user and switch to it
ENV SERVICE_NAME="minecraft"
ENV UID=1001 GID=1001
RUN \
	addgroup -g ${GID} -S ${SERVICE_NAME}; \
	adduser -u ${UID} -G ${SERVICE_NAME} -s /bin/false -D -H -S ${SERVICE_NAME}
USER ${SERVICE_NAME}

# Copy over scripts
ARG MC_BIN_DIR="mc-bin"
ENV PATH="${PATH}:/${MC_BIN_DIR}"
WORKDIR /${MC_BIN_DIR}
COPY --chown=${SERVICE_NAME}:${SERVICE_NAME} --chmod=500 ./misc-scripts/start.sh .
COPY --chown=${SERVICE_NAME}:${SERVICE_NAME} --chmod=500 ./misc-scripts/prepare.py .

# TODO:
# - copy things into image / run scripts that edit config files ???
# - should I put the entrypoint server start script somewhere that isn't gonna be mounted as a volume?
# 	but I don't want it to be excluded from server backups or hard to update
# 		- maybe a compromise could be making a pre-start script that will just properly alert the
# 		  user if the actual server start script is inaccessible or un-executable for any reason
# 		- I have decided that it doesn't matter at all if the start script is excluded from backups
# 		  since they still have the jar and can make their own start script using the docker-compose
# 		  file env vars or just on their own. the jar is the important thing.

WORKDIR /data
COPY --from=build --chown=${SERVICE_NAME}:${SERVICE_NAME} /build/server.jar .

VOLUME [ "/data" ]
VOLUME [ "/backups" ]

STOPSIGNAL SIGTERM
EXPOSE 25565

ENV JAR_NAME=server.jar MEMORY_AMOUNT="" EULA=""

ENTRYPOINT [ "/bin/start.sh" ]

# TODO:set up healthcheck?
