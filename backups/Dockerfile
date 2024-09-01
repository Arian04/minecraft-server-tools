# syntax = docker/dockerfile:1

ARG BUILDER_IMAGE
ARG BUILDER_IMAGE_TAG
ARG RUNNER_IMAGE
ARG RUNNER_IMAGE_TAG

##### Build #####
# build rcon client from source
FROM ${BUILDER_IMAGE}:${BUILDER_IMAGE_TAG} AS build

ARG GIT_REPO_URL="https://github.com/Tiiffi/mcrcon"
ARG COMMIT_SHA="b5951e96349ec2ecf72b468459fc503a7067ba1f"
ARG ZIP_URL="${GIT_REPO_URL}/archive/${COMMIT_SHA}.zip"
ARG EXPECTED_SHA256="04ed40ee90350e19c80643a37a499cd03c5c8d0d7b1342e43b56ac62de1db1de"

WORKDIR /src

# Dependencies
RUN apk add --no-cache \
	make \
	clang

# Get source, verify against the expected checksum, and extract
ADD --checksum="sha256:${EXPECTED_SHA256}" "${ZIP_URL}" source.zip
RUN unzip source.zip

WORKDIR /src/mcrcon-${COMMIT_SHA}

# Build
RUN \
	make; \
	mv ./mcrcon ../

##### Runtime #####
FROM ${RUNNER_IMAGE}:${RUNNER_IMAGE_TAG}

COPY --from=build --chmod=555 /src/mcrcon /bin

# borgbackup - backup software
# supercronic - cron
RUN apk add --no-cache borgbackup=1.2.7-r0 supercronic

# create non-root user and switch to it
# ENV SERVICE_NAME="minecraft"
# ENV UID=1001 GID=1001
# RUN \
# 	addgroup -g ${UID} -S ${SERVICE_NAME}; \
# 	adduser -u ${GID} -G ${SERVICE_NAME} -s /bin/false -D -H -S ${SERVICE_NAME}
# USER ${SERVICE_NAME}

# TODO: modify the way this works to make the time period configurable with env vars
COPY --chmod=500 ./backup.sh /bin/backup.sh
COPY crontab /etc/crontab

VOLUME [ "/data" ]
VOLUME [ "/backups" ]
WORKDIR /backups

CMD [ "supercronic", "/etc/crontab" ]
