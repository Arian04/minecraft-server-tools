#!/usr/bin/env python
import logging
import sys
from pathlib import Path
from typing import Annotated

import requests
import typer
from rich.logging import RichHandler

# Set up application and logging
app = typer.Typer(context_settings={
    "help_option_names": ["-h", "--help"],
    "show_default": False,  # For some reason, I still have to specify show_default=False for required args/options
})
logging.basicConfig(
    # level="WARN",
    level="DEBUG",
    format="%(message)s",
    datefmt="[%X]",
    handlers=[RichHandler()]
)
LOGGER = logging.getLogger("image_to_comic_pdf")


# NOTE: almost done, just gotta do some finishing touches
# TODO:
#   - use typer to polish it up
#       - also make each "type" of jar a subcommand?
#   - reduce code duplication (also all papermc projects will have the same implementation)

def save_file(url: str, path: str | Path) -> None:
    # DEBUG: this is just here until i'm confident everything's working well
    print(f"download from: {url}")
    print(f"write file to: {path}")
    return

    with open(path, "wb") as file:
        response = requests.get(url)
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
        sys.exit("uh oh i think something bad happened")

    return json_data


def get_latest_stable_fabric(mc_version):
    API_ENDPOINT = "https://meta.fabricmc.net/v2"

    # Version check, optional
    json_response = get_json(f"{API_ENDPOINT}/versions/game")
    for obj in json_response:
        if obj['stable'] is True and obj['version'] == mc_version:
            print(f'mc version {mc_version} is valid')
            break

    # get latest stable loader version
    json_response = get_json(f"{API_ENDPOINT}/versions/loader")
    loader_version = find_value_in_json(
        json_response,
        "version",
        ("stable", True)
    )
    if loader_version is None:
        sys.exit("couldn't get loader version")

    # get latest stable installer version
    json_response = get_json(f"{API_ENDPOINT}/versions/installer")
    installer_version = find_value_in_json(
        json_response,
        "version",
        ("stable", True)
    )
    if installer_version is None:
        sys.exit("couldn't get installer version")

    return f"{API_ENDPOINT}/versions/loader/{mc_version}/{loader_version}/{installer_version}/server/jar"


def get_latest_stable_purpur(mc_version):
    API_ENDPOINT = "https://api.purpurmc.org/v2/purpur"

    return f"{API_ENDPOINT}/{mc_version}/latest/download"


def get_latest_stable_velocity():
    API_ENDPOINT = "https://api.papermc.io/v2"
    PROJECT = "velocity"

    # Get latest version group
    json_response = get_json(f"{API_ENDPOINT}/projects/{PROJECT}")
    json_response = json_response['version_groups']  # we only care about the version groups
    latest_version_group = json_response[-1]  # get the last element (latest version group)

    # Get latest non-experimental (stable) build
    build_json = None
    json_response = get_json(f"{API_ENDPOINT}/projects/{PROJECT}/version_group/{latest_version_group}/builds")
    for obj in reversed(json_response['builds']):
        if obj['channel'] == 'default':
            build_json = obj
            break

    if build_json is None:
        sys.exit("failed to find a stable build")

    version = build_json['version']
    build_number = build_json['build']
    jar_name = build_json['downloads']['application']['name']
    # jar_sha256 = build_json['downloads']['application']['sha256']

    return f"{API_ENDPOINT}/projects/{PROJECT}/versions/{version}/builds/{build_number}/downloads/{jar_name}"


@app.command()
def main(
        jar_type: Annotated[
            str,
            typer.Argument(
                show_default=False,
                metavar="type"
            )
        ],
        path: Annotated[
            Path,
            typer.Argument(
                show_default=False,
                exists=False
            )
        ]
):
    # TODO:
    #  - un-hardcode input
    #  - figure out how to handle the fact that mc version is only required when downloading non-proxy jars
    mc_version = "1.20.2"

    jar_url = None
    match jar_type:
        case "fabric":
            jar_url = get_latest_stable_fabric(mc_version)
        case "purpur":
            jar_url = get_latest_stable_purpur(mc_version)
        case "velocity":
            jar_url = get_latest_stable_velocity()
        case _:
            sys.exit(f"invalid jar type: {jar_type}")


    save_file(jar_url, path)


if __name__ == '__main__':
    app()
