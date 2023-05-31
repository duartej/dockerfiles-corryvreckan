# CORRYVRECKAN-EUDAQ integration dockerfile

Creates the environment to run the [CORRYVRECKAN](https://gitlab.cern.ch/corryvreckan/corryvreckan)
analysis framework with the EUDAQ (v2) event reader support. 

## Image download and installation
1. Clone the docker eudaq repository and configure it
```bash 
$ git clone https://github.com/duartej/dockerfiles-corryvreckan.git
$ cd dockerfiles-corryvreckan
$ source setup.sh ${ANALISYS_DIR} [${CORRY_REPO}]
```
The ```setup.sh``` creates a ```docker-compose.yml``` and 
```docker-compose.override.yml``` files which they can be used with the
[docker-compose](https://docs.docker.com/compose) utility. Those files
will provide several useful services, including the service to build the 
image. The `ANALYSIS_DIR` is referring to a folder in the host shared 
with the container, and `CORRY_REPO` to the local repository of `corryvreckan`.
If not is provided, the script will try to clone it from the remote repository
in the host ```$HOME/repos/corryvreckan``` folder.

2. Download the automated build from the dockerhub: 
```bash
$ docker pull duartej/corryvreckan:latest
```
or alternativelly you can build an image from the
[Dockerfile](Dockerfile)
```bash
# A. Using docker
$ docker build github.com/duartej/corryvreckan:latest
# B. Using docker-compose
$ docker-compose build corryvreckan
```

## Usage
The `setup.sh` file will have created several services: 
 * `corryvreckan`: to build the image
 * `analysis`: the container provides a bash script where the `corry` executable is
               ready to be used. Note the `/data` folder is intended to be used as 
               working directory, and it is shared with the host computer
 * `devcode`:  as the `analysis` service, but the corryvreckan framework is mounted
               from the host (see ${CORRY_REPO}). Useful for code development. [override]
 * `compile`:  to compile the local repository. [override]

A service is started and run as usual: 

```bash
# Start the service setting up the development environment
$ docker-compose run --rm analysis
# Start the service setting up the development environment
$ docker-compose run --rm devcode
# In order to run an image of the container not using docker-compose,
# for instance, to create a new devcode
$ docker run -it --rm -v /tmp/.X11-unix:/tmp/.X11-unix --mount type=bind,source=${HOME}/repos/corryvreckan,target=/analysis/corryvreckan -e DISPLAY=unix${DISPLAY} duartej/corryvreckan
```


## Content
The image is built over a [phusion](https://github.com/phusion/baseimage-docker) image, which
is based on Ubuntu focal (20.1.1). It uses the [duartej/eudaqv1](https://github.com/duartej/dockerfiles-eudaqv1)
to extract eudaq (and its dependency boost-1.77) and ROOT 6.28. 

 * `/rootfr/root`: ROOT 6.24 libraries and source code
 * `/analysis/eudaq`: EUDAQ libraries and source code
 * `/analysis/boost`: BOOST 1.77 libraries
 * `/analysis/corryvreckan`: Corryvreckan libraries and source code
 * USER: `analyser`



