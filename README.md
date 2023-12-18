# minecraft-server-tools
This repo includes various tools I use for hosting containerized minecraft servers. 
More comprehensive tools exist, but I wanted something much more minimal. 

## Features
- None yet lol

## TODO
- [ ] basic Dockerfile
  - figure out how to handle initialization of container vs just running it
    - init minecraft files
    - create borg repo
- scripts
	- mc jar downloader
		- [ ] Fabric
		- [ ] Purpur
		- [ ] Velocity (proxy)
	- [ ] substitute env vars provided to container into appropriate config files
		- TODO: make list of files here
	- backups
      - [x] clean up old script and make it take arguments
	  - [ ] test it
      - [ ] make sure it writes to a directory that is intended to be exposed as a volume on the container host
