#!/usr/bin/env python3

# NOTE: It is important that this script stays idempotent since it will likely end up running on volumes
# that have already been set up by this script


import logging
import os
import re
import secrets
import string


def set_eula():
    EULA_VAR_NAME = "EULA"
    EULA_FILE_NAME = "eula.txt"
    if os.environ.get(EULA_VAR_NAME):
        with open(f"{SERVER_DIRECTORY}/{EULA_FILE_NAME}", "r") as file:
            file.write(f"eula=true")
    else:
        LOGGER.error("You must accept the Minecraft EULA before being able to run the server")


def set_rcon_vars():
    RCON_IS_ENABLED = os.getenv("ENABLE_RCON")
    RCON_PORT = os.getenv("RCON_PORT")
    RCON_PASSWORD = os.getenv("RCON_PASSWORD")

    if RCON_IS_ENABLED:
        if not RCON_PASSWORD:
            LOGGER.info("RCON_PASSWORD is not set, generating a secure password automatically")
            password_length = 63
            rcon_password = "".join(
                secrets.choice(string.ascii_uppercase + string.digits) for _ in range(password_length)
            )
            os.environ["RCON_PASSWORD"] = rcon_password

    else:
        LOGGER.info("skipping RCON setup since it's disabled")


# Normalize MC server property names so that they fit environment variable naming conventions
def property_to_env_var(prop: str):
    env_var = str.upper(prop)
    env_var = env_var.replace(".", "_")
    env_var = env_var.replace("-", "_")
    return env_var


# Edits config file relative to its location under server_dir
def set_server_properties():
    SERVER_PROPERTIES_FILE = f"{SERVER_DIRECTORY}/server.properties"

    # Read properties from file into list
    properties = []
    with open(f"{SERVER_PROPERTIES_FILE}", "r") as file:
        for line in file:
            properties.append(line.lstrip().rstrip())
    if properties is None:
        LOGGER.error("failed to read properties from %s", SERVER_PROPERTIES_FILE)
        return 1

    # NOTE: I'm assuming that you can't put comments in the same line as a key=value pair
    property_regex = re.compile(r"(^.*)=(.*)$")

    # Replace server properties with desired values
    for i, line in enumerate(properties):
        LOGGER.debug(f"current line: {line}")

        # if line is comment, skip it
        if line[0] == "#":
            continue

        # extract key and value names from line
        matches = property_regex.match(line)
        if matches is None:
            LOGGER.error("somethings wrong, config line didn't match")
            continue
        key = matches.group(1)
        value = matches.group(2)
        LOGGER.debug(f"found (key, value): ({key}, {value})")

        env_var_name = property_to_env_var(key)
        env_var = os.environ.get(env_var_name)
        if env_var is not None:
            LOGGER.info(f"{env_var_name} is set to {env_var}, setting property accordingly.")
            properties[i] = property_regex.sub(r"\1=" + f"{env_var}", line)

    # Writes all properties to file
    with open(f"{SERVER_PROPERTIES_FILE}", "w") as file:
        for line in properties:
            file.write(f"{line}\n")


def main():
    set_eula()
    set_rcon_vars()
    set_server_properties()


if __name__ == "__main__":
    logging.basicConfig(
        # level="WARN",
        level="DEBUG",
        format=" %(name)s :: %(levelname)-8s :: %(message)s",
        datefmt="[%X]",
    )
    LOGGER = logging.getLogger("mc_server_properties_editor")
    SERVER_DIRECTORY = "."

    main()
