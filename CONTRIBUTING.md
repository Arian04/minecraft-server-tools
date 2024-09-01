# General Notes
- Keep scope reasonable, I want this project to be pretty minimal and easy to audit.
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/) are used to keep build dependencies out of the runtime container.

### Server Container
- `build` directory: files required at container image build-time.
	- Scripts running in here can be "bloated" as long as they produce something minimal, since the "bloat" won't be copied into the container image during the build process.
- `runtime` directory: files required at container runtime.
	- Scripts here should be much more minimal. I'm trying to stick to POSIX-compliant shell scripts and simple python scripts.
	- `start.sh` is the container entrypoint that will run all other required scripts. This makes it easy to see what scripts are called and when. It'll also exit if any preparation scripts return a non-zero exit code, so all preparation scripts should make sure to only return that if the issue warrants it.

### Backup Container
Uses RCON and Borg to back up the server container.
RCON is used to disable auto-save during the backup to make sure world files don't change while reading them and to send messages in chat about the backup's status (started, finished, failed, etc.)
