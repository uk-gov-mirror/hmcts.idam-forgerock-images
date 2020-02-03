# DS local docker image

This is a vanilla version of Forgerock DS (version 6.5) docker image to install DS and manage it with docker-compose.  

## Getting Started

These instructions will provide you an image og Forgerock DS  

### Prerequisites

In order to create the docker image you need to download the Forgerock binary file: DS-6.5.2.zip
You can obtain this either form the backstage download page(if you have an account) or maybe you can ask to your colleagues....

```
DOWNLOAD  DS-6.5.2.zip
```

### Installing  

DS can be configured as AM Config store, Userstore and Core Token Service (CTS).  
In the version 6.5 you can use the "profile command" to run the appropriate ldif template and configure DS as required. Ldif templates could be found in opendj.zip (template/setup-profiles). 
You can find more information on [Forgerock ds installation guide](https://backstage.forgerock.com/docs/ds/6.5/install-guide/index.html#setup-profiles-am-config)

Depending on the value of env variable "DS_TYPE", a different profile is used during the installation.  
The default behaviour is configure everything in the same instance.  
You should define the DS_TYPE value in the docker-compose file. Here below DS_TYPE possible values:
```
Config And CTS --> DS_TYPE=cfgAndCts  
Userstore --> DS_TYPE=userstore  
Config, Userstore and CTS --> DS_TYPE=
```

- Dockerfile: defines installation folders and all the environment variables
- run.sh: manages installation logic (i.e. profiles, server restart)

STEPS:  
1. Rename the  DS-6.5.2.zip into opendj.zip and copy it into 'ds' folder.
2. build the image
```
docker build --tag forgerock_6.5/test-ds:6.5.2 ds
```



