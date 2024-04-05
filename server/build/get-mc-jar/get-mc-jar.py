#!/usr/bin/env python

import hashlib
import logging
import sys
from pathlib import Path
from typing import Optional

import requests
import typer
from rich.logging import RichHandler
from typing_extensions import Annotated

# NOTE: yea yea, I know it's bloated, but Typer and Rich are nice and sometimes I wanna run this interactively.

# Set up application and logging
app = typer.Typer(
    context_settings={
        "help_option_names": ["-h", "--help"],
    }
)
logging.basicConfig(
    # level="WARN",
    level="DEBUG",
    format="%(message)s",
    datefmt="[%X]",
    handlers=[RichHandler()],
)
LOGGER = logging.getLogger("mc_jar_downloader")

# The reason I'm hardcoding the latest stable MC version and not the latest proxy version is because the proxy versions
# should (I believe) work for any backend mc server version, but blindly grabbing the latest Minecraft version wouldn't
# be the best idea due to how much could break (mods/plugins, farms, etc.)
LATEST_MC_VERSION = "1.20.4"

# I'm only using this as an indicator to know when to find the latest version at runtime
LATEST_PROXY_VERSION = "latest"


# ----- Helper Functions -----
def save_file_verify_sha256sum(file_url: str, path: Path, checksum: str) -> None:
    return save_file_verify_checksum(file_url, path, hashlib.sha256, checksum)


def save_file_verify_md5sum(file_url: str, path: Path, checksum: str) -> None:
    return save_file_verify_checksum(file_url, path, hashlib.md5, checksum)


def save_file_verify_checksum(file_url: str, path: Path, hash_constructor, checksum: str) -> None:
    LOGGER.info(f"jar file will be downloaded from: {file_url}")
    LOGGER.info(f"file will be written to: {path}")

    # download file
    response = requests.get(file_url)

    # verify checksum
    calculated_hash = hash_constructor(response.content).hexdigest()
    if calculated_hash != checksum:
        LOGGER.error(
            f"checksum verification failed, not writing file. expected '{checksum}', got '{calculated_hash}'"
        )
        sys.exit(1)

    # write file
    with open(path, "wb") as file:
        file.write(response.content)


def save_file_unsafe(file_url: str, path: Path) -> None:
    LOGGER.info(f"jar file will be downloaded from: {file_url}")
    LOGGER.info(f"file will be written to: {path}")

    response = requests.get(file_url)
    with open(path, "wb") as file:
        file.write(response.content)


def find_value_in_json(json, return_key: str, search_tuple):
    find_key = search_tuple[0]
    matching_value = search_tuple[1]
    for obj in json:
        if obj[find_key] == matching_value:
            return obj[return_key]

    return None


def get_json(url: str):
    response = requests.get(url)
    json_data = response.json()

    if not json_data:
        LOGGER.error("uh oh, this is NOT json data")
        sys.exit(1)

    return json_data


# ----- Main Functions -----
@app.command()
def fabric(
    path: Annotated[Path, typer.Argument(show_default=False, exists=False)],
    mc_version: Annotated[Optional[str], typer.Argument(show_default=False)] = LATEST_MC_VERSION,
) -> int:
    API_ENDPOINT = "https://meta.fabricmc.net/v2"

    # Check that the version is available
    version_is_available = False
    mc_version_list = get_json(f"{API_ENDPOINT}/versions/game")
    for obj in mc_version_list:
        if obj["version"] == mc_version:
            LOGGER.debug(f"mc version {mc_version} is valid")
            version_is_available = True
            break
    if not version_is_available:
        LOGGER.error(f"version '{mc_version}' is not available :(")
        return 1

    # get latest stable loader version
    loader_version_list = get_json(f"{API_ENDPOINT}/versions/loader")
    loader_version = find_value_in_json(loader_version_list, "version", ("stable", True))
    if loader_version is None:
        LOGGER.error("couldn't get loader version")
        return 1

    # get latest stable installer version
    installer_version_list = get_json(f"{API_ENDPOINT}/versions/installer")
    installer_version = find_value_in_json(installer_version_list, "version", ("stable", True))
    if installer_version is None:
        LOGGER.error("couldn't get installer version")
        return 1

    jar_url = f"{API_ENDPOINT}/versions/loader/{mc_version}/{loader_version}/{installer_version}/server/jar"
    save_file_unsafe(jar_url, path)
    return 0


@app.command()
def purpur(
    path: Annotated[Path, typer.Argument(show_default=False, exists=False)],
    mc_version: Annotated[Optional[str], typer.Argument(show_default=False)] = LATEST_MC_VERSION,
) -> int:
    API_ENDPOINT = "https://api.purpurmc.org/v2/purpur"

    # Check that the version is available
    version_list = get_json(f"{API_ENDPOINT}")["versions"]
    if mc_version not in version_list:
        LOGGER.error(f"version '{mc_version}' is not available :(")
        return 1

    latest_build_info = get_json(f"{API_ENDPOINT}/{mc_version}/latest")
    build_number = latest_build_info["build"]
    md5sum = latest_build_info["md5"]
    jar_url = f"{API_ENDPOINT}/{mc_version}/{build_number}/download"
    save_file_verify_md5sum(jar_url, path, md5sum)
    return 0


@app.command()
def paper(
    path: Annotated[Path, typer.Argument(show_default=False, exists=False)],
    mc_version: Annotated[str, typer.Argument(show_default=False)] = LATEST_MC_VERSION,
) -> int:
    PROJECT = "paper"
    return papermc(PROJECT, path, mc_version)


@app.command()
def waterfall(
    path: Annotated[Path, typer.Argument(show_default=False, exists=False)],
    proxy_version: Annotated[str, typer.Argument()] = LATEST_PROXY_VERSION,
) -> int:
    PROJECT = "waterfall"
    return papermc(PROJECT, path, proxy_version)


@app.command()
def velocity(
    path: Annotated[Path, typer.Argument(show_default=False, exists=False)],
    proxy_version: Annotated[str, typer.Argument()] = LATEST_PROXY_VERSION,
) -> int:
    PROJECT = "velocity"
    return papermc(PROJECT, path, proxy_version)


# All PaperMC projects share the same implementation for downloading the jar
def papermc(project: str, path: Path, version: str) -> int:
    API_ENDPOINT = "https://api.papermc.io/v2"
    PROXIES = {"velocity", "waterfall"}

    version_list = get_json(f"{API_ENDPOINT}/projects/{project}")["versions"]
    if project in PROXIES and version is LATEST_PROXY_VERSION:
        # turn LATEST_PROXY_VERSION constant into the actual latest version
        version = version_list[-1]  # the last element is the latest version
    else:
        # Check that the version is available
        if version not in version_list:
            LOGGER.error(f"version '{version}' is not available :(")
            return 1

    # Get latest non-experimental (stable) build for the given version
    build_json = None
    builds_list = get_json(f"{API_ENDPOINT}/projects/{project}/versions/{version}/builds")["builds"]

    # Reverse the list because they provide it in "oldest first" order
    for build in reversed(builds_list):
        if build["channel"] == "default":
            build_json = build
            break

    if build_json is None:
        LOGGER.error("failed to find a stable build")
        return 1

    build_number = build_json["build"]
    jar_name = build_json["downloads"]["application"]["name"]
    sha256sum = build_json["downloads"]["application"]["sha256"]

    jar_url = (
        f"{API_ENDPOINT}/projects/{project}/versions/{version}/builds/{build_number}/downloads/{jar_name}"
    )
    save_file_verify_sha256sum(jar_url, path, sha256sum)
    return 0


if __name__ == "__main__":
    app()
