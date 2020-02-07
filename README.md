# IDAM ForgeRock Images Builder

The goal of this script is to build Docker images containing ForgeRock used for local development.
The following images/services are included:

- ForgeRock AM
- ForgeRock DS
- ForgeRock IDM
- Postgres shared database

This repository uses the `cnp-idam-packer` repository (as git submodule) to source the FR configuration from.

## Prerequisites

In order to build the images you have to put binary ForgeRock files in the `bin/` directory first.

The required files are:
- `AM-x.x.x.x.war`
- `Amster-x.x.x.x.zip`
- `DS-x.x.x.zip`
- `IDM-x.x.x.x.zip`

You can download these files from [https://backstage.forgerock.com/downloads/](https://backstage.forgerock.com/downloads/).

## Usage

### Running the script

Currently, the script doesn't require any parameters:

`> ./build.sh`

### Overriding the default configuration branch

By default, the script assumes that the configuration is taken from the `preview` branch of the config repository.
If the currently checked-out branch in the git submodule is not what is expected, the script will stop. The script will also quietly ignore all the local changes to the repository.

If you want to use another branch, you can override this env variable:

```shell script
CONFIGURATION_BRANCH=master ./build.sh
```

### Overriding the default binaries versions

By default, the script assumes that individual ForgeRock's services' binaries use certain fixed file names.
You can temporarily override these by supplying different values for the following env variables:

```shell script
FORGEROCK_AM_FILE=my-am-file-name \
FORGEROCK_AMSTER_FILE=my-amster-file-name \
FORGEROCK_DS_FILE=my-ds-file-name \
FORGEROCK_IDM_FILE=my-idm-file-name \
./build.sh
```

If you want to change the versions permanently (e.g. FR upgrade), it is recommended to modify the script instead.

### Overriding the default Docker tag

By default, the script tags all the Docker images using `fr-local` prefix. You can override it by setting the following env variable:

```shell script
DOCKER_IMAGE_PREFIX=my-local-forgerock ./build.sh
```

The script additionally tags all the images with `latest`, which is used in the provded `docker-compose` file(s).
