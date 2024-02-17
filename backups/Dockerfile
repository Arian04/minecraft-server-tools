# syntax = docker/dockerfile:1

##### Build #####
# build rcon client from source
FROM alpine:3.19 AS build

ARG GIT_REPO_URL="https://github.com/Tiiffi/mcrcon"
ARG COMMIT_SHA="b5951e96349ec2ecf72b468459fc503a7067ba1f"
ARG ZIP_URL="${GIT_REPO_URL}/archive/${COMMIT_SHA}.zip"
ARG EXPECTED_SHA512="887b2a6147605a03a807548aa77790ee9341139e9b047414311d0216e8c67d21f02681eb438b3e6ad6b12a92703e1dc49304a35d1fafdda7fd0e2659b1d58a27"

WORKDIR /src

# Dependencies
RUN apk add --no-cache \
	make \
	clang

# Get source, verify against the expected checksum, and extract
RUN \
	wget -q ${ZIP_URL} -O source.zip; \
	echo "${EXPECTED_SHA512}  source.zip" > checksum.txt; \
	sha512sum -c -s checksum.txt; \
	unzip source.zip

WORKDIR /src/mcrcon-${COMMIT_SHA}

# Build
RUN \
	make; \
	mv ./mcrcon ../

##### Runtime #####
FROM alpine:3.19

COPY --from=build --chmod=555 /src/mcrcon /usr/bin/mcrcon

RUN apk add --no-cache borgbackup=1.2.7-r0

# create non-root user and switch to it
# ENV SERVICE_NAME="minecraft"
# ENV UID=1001 GID=1001
# RUN \
# 	addgroup -g ${UID} -S ${SERVICE_NAME}; \
# 	adduser -u ${GID} -G ${SERVICE_NAME} -s /bin/false -D -H -S ${SERVICE_NAME}
# USER ${SERVICE_NAME}

# TODO: modify the way this works to make the time period configurable with env vars
COPY --chmod=500 ./backup.sh /etc/periodic/hourly/backup.sh

VOLUME [ "/data" ]
VOLUME [ "/backups" ]
WORKDIR /backups

ENTRYPOINT [ "crond", "-f", "-d6", "-l8" ]
