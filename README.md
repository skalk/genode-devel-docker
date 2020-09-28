# genode-devel-docker
Utility to handle a docker image/container for Genode development

Dockerfile
==========

Recipe to create the docker image containing all tools needed to
compile and test Genode OS framework components as well as its
used 3rd party code.

docker
======

A small helper tool to create and instantiate a Genode development
docker container, and to manage the docker image needed.

Usage:

./docker [COMMAND]

--- whereby COMMAND is one of the following ---

* build  : build and export genode docker image from scratch
* import : import pre-build docker image from genode.org
* run    : create and run interactive genode docker container
* admin  : spawn container root instance with genode docker image
* clean  : delete genode docker images

--- the following variables are used within the commands ---

* MAKE_JOBS             : number of parallel jobs for build (default: 4)
* SUDO                  : optional sudo command (default: empty)
* DOCKER_CONTAINER_ARGS : additional arguments for docker container creation
