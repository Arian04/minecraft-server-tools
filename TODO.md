# TODO

- features
    - mc jar downloader
        - jar support
            - [X] Paper
            - [X] Fabric
            - [X] Purpur
            - [X] Velocity (proxy)
            - [X] Waterfall (proxy)
    - substitute env vars provided to container into appropriate config files
		- [X] server.properties
		- [ ] ops.json
        - [ ] whitelist.json
        - TODO: add more files to the list here
    - backups
		- [ ] make the borg repo name editable using an env var
		- [ ] allow user to easily change backup frequency
	- other
		- [ ] make container UID/GID more flexible + just generally address permission weirdness

- CI
	- [ ] somehow trigger CI on any jar updates (poll their APIs?? Just schedule a nightly build??)
	- [ ] add server jar build number to image tag
	- [ ] if I do it with a schedule, figure out a way to have it exit early if the jar build number and my commit hash are the same as a previous build (so it doesn't waste time rebuilding an image that's already made)

- cleanup
    - [ ] maybe add some more error-handling in mc jar downloader script
	- [X] reduce duplication of build args between CI and docker-compose build files
	- [X] make backup container not run as root
