The goal of this project(idam-forgerock-images) is to build Docker images containing ForgeRock used for local development. The following images/services are included:

ForgeRock AM
ForgeRock DS
ForgeRock IDM
Postgres shared database
This repository uses the cnp-idam-packer repository (as git submodule) to source the FR configuration from.

Prerequisites
The docker files and related build scripts can be found in the following project on the hmcts github, clone this project to a local directory.

https://github.com/hmcts/idam-forgerock-images

Please checkout the following branch feature/SIDM-3500

You will need the below tools installed on your local system

docker
docker-compose
If using windows please use a linux terminal (e.g. cygwin) to execute any scripts in the following sections

In order to build the images you have to put the below ForgeRock binary files in the idam-forgerock-images/bin directory of the idam-forgerock-images project first.

The required files are:

AM-6.5.2.2.war
Amster-6.5.2.2.zip
DS-6.5.2.zip
IDM-6.5.0.2.zip

You can download these files from Forgerock Backstage Download:
https://backstage.forgerock.com/downloads/browse/am/archive/productId:am/minorVersion:6.5/version:6.5.2.2
https://backstage.forgerock.com/downloads/browse/am/archive/productId:amster/minorVersion:6.5/version:6.5.2.2/releaseType:full
https://backstage.forgerock.com/downloads/browse/ds/archive/productId:ds/minorVersion:6.5/version:6.5.2
https://backstage.forgerock.com/downloads/browse/ig/archive/productId:ig/minorVersion:6.5

You can also find them in Azure idamstoragenonprod: https://portal.azure.com/#blade/Microsoft_Azure_Storage/ContainerMenuBlade/overview/storageAccountId/%2Fsubscriptions%2F1c4f0704-a29e-403d-b719-b90c34ef14c9%2FresourceGroups%2Fcore-infra-idam-storage%2Fproviders%2FMicrosoft.Storage%2FstorageAccounts%2Fidamstoragenonprod/path/idamstoragenonprod/etag/%220x8D5B08324BE4216%22/defaultEncryptionScope/%24account-encryption-key/denyEncryptionScopeOverride//defaultId//publicAccessVal/None

Usage
Running the script

To build the docker images execute the following build script from the root directory of the idam-forgerock-images project

  ./build.sh
Important

Please check the following script in the idam-forgerock-images/idm directory have executable permissions before running the build.sh script

build_config.sh
import_internal_roles.sh
 If they don't please change the file to permission to executable using chmod +x

.

Running containers

To run the containers execute the following docker-compose command from the root directory of the idam-forgerock-images project

  docker-compose -f docker-compose.yml -f docker-compose-local.yml up


Below is the list of applications and the ports and credentials used to access them.

IDM

Port : 8081 

Username: openidm

Password: openidm

AM

Please add the following host mappings to your local hosts file, and make sure to access AM using the host name and not localhost.

localhost  fr-am.local 
Port: 8181

Username: amadmin

Password: Pa55word11

DS

Config/Token Store

Port: 7389

Identity store

Port: 9389

Username: cn=Directory Manager

Password: Pa55word11

Connecting local idam api to local forgerock images
To get the local forgerock images working with idam-api use the following application-local.yaml



Place this file in the following directory idam-api\idam-api\src\main\resources\

Before starting up idam-api  use the following spring profile setting -Dspring.profiles.active=local



Overriding the default configuration branch
By default, the script assumes that the configuration is taken from the preview branch of the config repository. If the currently checked-out branch in the git submodule is not what is expected, the script will stop. The script will also quietly ignore all the local changes to the repository.

If you want to use another branch, you can override this env variable:

CONFIGURATION_BRANCH=master ./build.sh

Overriding the default binaries versions
By default, the script assumes that individual ForgeRock's services' binaries use certain fixed file names. You can temporarily override these by supplying different values for the following env variables:

FORGEROCK_AM_FILE=my-am-file-name \ FORGEROCK_AMSTER_FILE=my-amster-file-name \ FORGEROCK_DS_FILE=my-ds-file-name \ FORGEROCK_IDM_FILE=my-idm-file-name \ ./build.sh

If you want to change the versions permanently (e.g. FR upgrade), it is recommended to modify the script instead.

Overriding the default Docker tag
By default, the script tags all the Docker images using fr-local prefix. You can override it by setting the following env variable:

DOCKER_IMAGE_PREFIX=my-local-forgerock ./build.sh




