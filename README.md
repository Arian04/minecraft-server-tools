# minecraft-server-tools

This repo includes various tools I use for hosting containerized minecraft servers.
More comprehensive tools exist, but I wanted something much more minimal.

NOTE: currently a WIP, significant features are missing, and it's not tested very thoroughly

## Features

- automatically use the appropriate server jar without you having to go out and download it
- it's containerized, which comes with several benefits:
	- easier to handle networking for multiple MC servers on a single host
	- servers are more isolated. Ex: a Java update won't accidentally break another server running a version of Minecraft that requires a different Java version
	- easier to move the MC server(s) to a different host if necessary, since dependencies are packaged nicely into the container image
- server.properties is changed using simple environment variables, rather than having to manually change it
- simple incremental, compressed, and deduplicated backups via Borg by simply running a second lightweight container alongside the main server
- provided example docker-compose.yml makes it easy to get started

## TODO

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

- [ ] reduce duplication of build args between CI and docker-compose build files
