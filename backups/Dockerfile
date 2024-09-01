# syntax = docker/dockerfile:1

ARG BUILDER_IMAGE=alpine
ARG BUILDER_IMAGE_TAG=3.19
ARG RUNNER_IMAGE=alpine
ARG RUNNER_IMAGE_TAG=3.19

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

ENV BORG_BASE_DIR="/borg-base-dir"
ENV USERNAME="backups"
ENV UID=1000 GID=1000

COPY --from=build --chmod=555 /src/mcrcon /bin

# borgbackup - backup software
# supercronic - cron
RUN apk add --no-cache borgbackup=1.2.7-r0 supercronic

RUN addgroup -g ${GID} -S ${USERNAME} && \
	adduser -u ${UID} -G ${USERNAME} -s /bin/false -D -H -S ${USERNAME}

# Create borg base directory for unprivileged user
RUN mkdir -m 700 "${BORG_BASE_DIR}" && \
	chown ${UID}:${GID} "${BORG_BASE_DIR}"

USER "${USERNAME}"

# TODO: modify the way this works to make the time period configurable with env vars
COPY --chown="${UID}" --chmod=500 ./backup.sh /bin/backup.sh
COPY crontab /etc/crontab

VOLUME [ "/data" ]
VOLUME [ "/backups" ]
WORKDIR /backups

CMD [ "supercronic", "/etc/crontab" ]
