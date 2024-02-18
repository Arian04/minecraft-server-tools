# minecraft-server-tools

This repo includes various tools I use for hosting containerized minecraft servers.
More comprehensive tools exist, but I wanted something much more minimal.

## Features

- None yet lol

## TODO

- [X] basic Dockerfile
    - figure out how to handle initialization of container vs just running it
        - init minecraft files
        - create Borg repo
- scripts
    - mc jar downloader
        - jar support
            - [ ] Paper
            - [X] Fabric
            - [X] Purpur
            - [X] Velocity (proxy)
            - [ ] Waterfall (proxy)
        - [ ] Clean up the script a bit
    - substitute env vars provided to container into appropriate config files
		- [X] server.properties
        - TODO: make list of other files here
    - backups
        - [x] clean up old script and make it take arguments
        - [ ] test it
        - [ ] make sure it writes to a directory that is intended to be exposed as a volume on the container host

- [ ] reduce duplication of build args between CI and docker-compose build files
