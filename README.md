# IDAM ForgeRock Images Builder

The goal of this script is to build Docker images containing ForgeRock used for local development.

## Prerequisites

In order to build the images you have to put binary ForgeRock files in the `bin/` directory first.

The required files are:
- `AM-x.x.x.x.war`
- `Amster-x.x.x.x.zip`
- `DS-x.x.x.zip`
- `IDM-x.x.x.x.zip`

You can download these files from [https://backstage.forgerock.com/downloads/](https://backstage.forgerock.com/downloads/).
After placing the binery files in the `bin` directory, please make sure that the script knows what are their exact file names
(see: `build.sh`, `FORGEROCK_??_FILE` variables).

## Usage

Currently, the script doesn't require any parameters:

`> ./build.sh`