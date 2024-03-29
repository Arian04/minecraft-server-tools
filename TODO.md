# TODO

- scripts
    - mc jar downloader
        - jar support
            - [X] Paper
            - [X] Fabric
            - [X] Purpur
            - [X] Velocity (proxy)
            - [X] Waterfall (proxy)
        - [ ] maybe add some more error-handling
    - substitute env vars provided to container into appropriate config files
		- [X] server.properties
        - TODO: make list of other files here
    - backups
        - [x] clean up old script and make it take arguments
        - [x] test it

- other
	- [ ] reduce duplication of build args between CI and docker-compose build files
	- [ ] make backup container not run as root
	- [ ] make UID/GID more flexible and just generally address permission weirdness
