# IDAM ForgeRock Images

The script purpose it to build ForgeRock images for Docker.

## Obtaining ForgeRock Artifactory API Key

To get your API KEY, please follow these instructions:
https://backstage.forgerock.com/docs/platform/6.5/devops-guide/#devops-implementation-docker-downloader-steps

The key needs to be available to the script as `FR_API_KEY` env variable.

## When to rebuild the images

According to FR documentation:

> A Docker image's contents are static, so if you need to change the content in the image, you must rebuild it. Rebuild images when:
>
> - You want to upgrade to newer versions of AM, Amster, IDM, IG or DS software.
> - You changed files that impact an image's content. Some examples:
>     - Changes to security files, such as passwords and keystores.
>     - Changes to file locations or other bootstrap configuration in the AM boot.json file.
>     - Dockerfile changes to install additional software on the images.