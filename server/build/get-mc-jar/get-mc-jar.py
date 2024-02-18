#!/usr/bin/env python
import logging
import sys
from pathlib import Path
from typing import Optional

import requests
import typer
from rich.logging import RichHandler
from typing_extensions import Annotated

# NOTE: yea yea, I know it's bloated, but Typer and Rich are nice and sometimes i wanna run this interactively.

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
LATEST_MC_VERSION = "1.20.4"  # default version to download


# TODO: slight code duplication between each "server" jar and each "proxy" jar (args are the same)


# ----- Helper Functions -----
def save_file(file_url: str, path: Path) -> None:
    print(f"jar file will be downloaded from: {file_url}")
    print(f"file will be written to: {path}")

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
        LOGGER.error("uh oh i think something bad happened")
        sys.exit(1)

    return json_data


# ----- Main Functions -----
@app.command()
def fabric(
    path: Annotated[Path, typer.Argument(show_default=False, exists=False)],
    mc_version: Annotated[Optional[str], typer.Argument(show_default=False)] = LATEST_MC_VERSION,
) -> int:
    API_ENDPOINT = "https://meta.fabricmc.net/v2"

    # version check, optional
    json_response = get_json(f"{API_ENDPOINT}/versions/game")
    for obj in json_response:
        if obj["stable"] is True and obj["version"] == mc_version:
            print(f"mc version {mc_version} is valid")
            break

    # get latest stable loader version
    json_response = get_json(f"{API_ENDPOINT}/versions/loader")
    loader_version = find_value_in_json(json_response, "version", ("stable", True))
    if loader_version is None:
        LOGGER.error("couldn't get loader version")
        return 1

    # get latest stable installer version
    json_response = get_json(f"{API_ENDPOINT}/versions/installer")
    installer_version = find_value_in_json(json_response, "version", ("stable", True))
    if installer_version is None:
        LOGGER.error("couldn't get installer version")
        return 1

    jar_url = f"{API_ENDPOINT}/versions/loader/{mc_version}/{loader_version}/{installer_version}/server/jar"
    save_file(jar_url, path)


@app.command()
def purpur(
    path: Annotated[Path, typer.Argument(show_default=False, exists=False)],
    mc_version: Annotated[Optional[str], typer.Argument(show_default=False)] = LATEST_MC_VERSION,
) -> int:
    API_ENDPOINT = "https://api.purpurmc.org/v2/purpur"

    # TODO: add check to make sure mc_version is valid
    if False:
        return 1

    jar_url = f"{API_ENDPOINT}/{mc_version}/latest/download"
    save_file(jar_url, path)
    return 0


@app.command()
def velocity(
    path: Annotated[Path, typer.Argument(show_default=False, exists=False)],
    proxy_version: Annotated[Optional[str], typer.Argument()] = "latest",
) -> int:
    PROJECT = "velocity"
    return papermc(PROJECT, path, proxy_version)


# All PaperMC projects share the same implementation for downloading the jar
def papermc(project: str, output_path: Path, version: str) -> int:
    API_ENDPOINT = "https://api.papermc.io/v2"

    # TODO: finish this
    PROXIES = {"velocity", "waterfall"}
    if project in PROXIES:
        # validate proxy version differently if given???
        pass
    else:
        # do some mc version arg validation
        pass

    # Get latest version group
    json_response = get_json(f"{API_ENDPOINT}/projects/{project}")
    json_response = json_response["version_groups"]  # we only care about the version groups
    latest_version_group = json_response[-1]  # get the last element (latest version group)

    # Get latest non-experimental (stable) build
    build_json = None
    json_response = get_json(f"{API_ENDPOINT}/projects/{project}/version_group/{latest_version_group}/builds")
    for obj in reversed(json_response["builds"]):
        if obj["channel"] == "default":
            build_json = obj
            break

    if build_json is None:
        LOGGER.error("failed to find a stable build")
        return 1

    version = build_json["version"]
    build_number = build_json["build"]
    jar_name = build_json["downloads"]["application"]["name"]
    # jar_sha256 = build_json['downloads']['application']['sha256']

    jar_url = (
        f"{API_ENDPOINT}/projects/{project}/versions/{version}/builds/{build_number}/downloads/{jar_name}"
    )
    save_file(jar_url, output_path)
    return 0


if __name__ == "__main__":
    app()
