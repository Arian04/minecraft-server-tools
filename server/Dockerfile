# syntax = docker/dockerfile:1

# TODO: lots of hardcoded paths, I wonder if there's a standard way that people handle that issue

##### Build #####
# uses my script to download the required jar file
FROM python:alpine3.19 AS build

ARG type=fabric
ARG version=1.20.4

WORKDIR /opt/minecraft

COPY ./misc-scripts/get-mc-jar .
RUN pip install --no-cache-dir -r ./requirements.txt
RUN ./get-mc-jar.py ${type} server.jar ${version}

##### Runtime #####
FROM eclipse-temurin:17-jre-alpine

# Minecraft warns when udev isn't available. Not sure what actually happens if it's missing though.
RUN apk add --no-cache udev

# create non-root user and switch to it
ENV SERVICE_NAME="minecraft"
RUN \
	addgroup -g 1001 -S ${SERVICE_NAME}; \
	adduser -u 1001 -G ${SERVICE_NAME} -s /bin/false -D -H -S ${SERVICE_NAME}
USER ${SERVICE_NAME}

WORKDIR /data

COPY --from=build --chown=${SERVICE_NAME}:${SERVICE_NAME} /opt/minecraft/server.jar .

ENV UID=1001 GID=1001

# things to do here:
# - copy things into image / run scripts that edit config files ???
# - should I put the entrypoint server start script somewhere that isn't gonna be mounted as a volume?
# 	but I don't want it to be excluded from server backups or hard to update
# 		- maybe a compromise could be making a pre-start script that will just properly alert the
# 		  user if the actual server start script is inaccessible or un-executable for any reason

COPY --chown=${SERVICE_NAME}:${SERVICE_NAME} --chmod=500 ./misc-scripts/start.sh .

VOLUME [ "/data" ]
VOLUME [ "/backups" ]

STOPSIGNAL SIGTERM
EXPOSE 25565

ENV TYPE="" VERSION="" JAR_NAME=server.jar MEMORY_AMOUNT=1G EULA=""

ENTRYPOINT [ "/data/start.sh" ]

# TODO:set up healthcheck?
