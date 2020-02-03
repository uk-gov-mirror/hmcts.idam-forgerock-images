# IDAM ForgeRock Images

The goal of this script is to build Docker images containing ForgeRock used in local development.

## Prerequisites

In order to build the images you have to put binary ForgeRock files in the `bin/` directory.

The require files are:
- `AM-x.x.x.x.war`
- `Amster-x.x.x.x.zip`
- `DS-x.x.x.zip`
- `IDM-x.x.x.x.zip`

You can download these files from [https://backstage.forgerock.com/downloads/](https://backstage.forgerock.com/downloads/).

## Usage

Currently, the script doesn't require any parameters:

`> ./build.sh`