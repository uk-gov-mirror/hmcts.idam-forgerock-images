# IDAM ForgeRock Images

The script purpose it to build ForgeRock images for Docker for local development.

> Note: This script was created with MacOS in mind.

## General process description

The process of building and deploying ForgeRock consists of the following stages:

### Preparation

#### Installing required tools

The script requires the following tools installed on your local machine:

- git
- docker
- kubectl
- helm
- kubectx
- stern
- minikube
- kubens
- VirtualBox

#### Obtaining ForgeRock Artifactory API Key

In order to build ForgeRock Docker Images, you need an API key to access the binary repository.
To get your API key, please follow these instructions:
https://backstage.forgerock.com/docs/platform/6.5/devops-guide/#devops-implementation-docker-downloader-steps

The obtained key needs to be available to the script as `FR_API_KEY` env variable.

#### Providing SSH key to access the configuration repository

Before you deploy ForgeRock to your local Kubernetes instance you must make sure that the correct configuration is available.
In order to get the configuration, ForgeRock connects to a dedicated Git repository, clones it and makes it available to all FR services.
The configuration repository is the `forgeops-config` repository, included in this one in form of a git submodule.

Before deploying:
- please make sure that the submodule has the correct branch checked out
- set the `CONFIG_REPO_PRIVATE_KEY_PATH` variable to the path of the private key (`id_rsa`) used to access the configuration repository

### Configuring Kubernetes

This stage configures your local Kubernetes instance to run ForgeRock. This includes things like:

- starting the cluster
- installing certificate manager
- setting-up Helm
- enabling Ingress Controller
- creating the target namespace

### Building the Downloader Docker Image

The so-called Downloader Docker Image serves as a base image for all the other FR images. You are normally required to do it only once.

> Note: The images will be built for the Minikube's Docker, not the one installed on your machine.
> For this reason the script switches you local Docker to use Minikube's registry, then it switches it back on exit.

### Building the rest of the ForgeRock Docker Images

The currently supported images are:

- AM
- DS
- IDM

> Note: IG is currently **not supported**.

### Deploying ForgeRock to Kubernetes



## When to rebuild the images

According to FR documentation:

> A Docker image's contents are static, so if you need to change the content in the image, you must rebuild it. Rebuild images when:
>
> - You want to upgrade to newer versions of AM, Amster, IDM, IG or DS software.
> - You changed files that impact an image's content. Some examples:
>     - Changes to security files, such as passwords and keystores.
>     - Changes to file locations or other bootstrap configuration in the AM boot.json file.
>     - Dockerfile changes to install additional software on the images.

Normally, a change in configuration **should not** require images rebuild.
