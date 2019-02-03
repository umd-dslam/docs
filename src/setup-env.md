# Setting up Environment

In this section, you will learn how to setup the development environment. This project provides a flexible metadata storage layer to integrate different database systems into HDFS. For the sake of simplicity, only the Postgres integration is currently available.

The setup will be organized as follows:

0. Install Docker
1. Build a Postgres Docker Image
2. Build a Hadoop Development Environment Docker Image
3. Build new source code in Docker Container
4. Run Hadoop Benchmark

## Install Docker

Due to the complexity of this project, Hadoop compilation involves a lot of dependencies. It is very hard to reproduce the experimental results on bare metal. The best way to solve this problem for anyone is to use the Docker.

[Docker](https://en.wikipedia.org/wiki/Docker_(software)) is a computer program that performs operating-system-level virtualization. Docker is used to run software packages called "containers". Containers are isolated from each other and bundle their own application, tools, libraries and configuration files; they can communicate with each other through well-defined channels. All containers are run by a single operating-system kernel and are thus more lightweight than virtual machines. Containers are created from "images" that specify their precise contents. Images are often created by combining and modifying standard images downloaded from public repositories.

You can download and install Docker from this webpage: [https://docs.docker.com/install/](https://docs.docker.com/install/). Docker
is available on multiple platforms. For example, Desktop (Mac and Windows), Server (CentOS, Debian, Fedora and Ubuntu).


After installation, you can issue the command to verify its version:

```bash
$ docker --version

Docker version 18.05.0-ce, build f150324
```

## Build a Postgres Docker Image

Postgres image is built by a [Dockerfile](https://github.com/DSL-UMD/hadoop-calvin/blob/calvin/Dockerfile):

```bash
$ cd $project_directory  # where Dockerfile is located
$ docker build -t eg_postgresql . # build a Docker image
```

Note: `postgresql-9.3` was packaged into Docker image, to change its version, please check out [Dockerfile#L20](https://github.com/DSL-UMD/hadoop-calvin/blob/calvin/Dockerfile#L20)!

`docker images` can list all images built locally or downloaded from registry:

```bash
$ docker images

REPOSITORY             TAG          IMAGE ID            CREATED             SIZE
eg_postgresql          latest       efb054f3e4d1        8 weeks ago         421MB
```

Now, you can start a Postgres container (in the background):

```bash
$ docker run -d -p 5432:5432 --name pg_test eg_postgresql
```

Note: docker run [OPTIONS] IMAGE [COMMAND] [ARG...]

- -d: Run container in background and print container ID
- --name: Assign a name to the container
- -p: Publish a container's port(s) to the host


`docker ps` can list all alive containers.

```bash
$ docker ps

CONTAINER ID        IMAGE               COMMAND         CREATED        STATUS          PORTS    NAMES
a07214073fc3        hadoop-build-501    "/bin/bash"     9 hours ago    Up 9 hours               hadoop-dev
```

## Build a Hadoop Development Environment Docker Image

Fortunately, official Hadoop team already used Docker as their daily testbed.
We added a few software (`postgresql-client` and `jdbc`) in offical script to access `postgressql-9.3` in the previous container: **pg_test**.

These incremental commands are added in [start-build-env.sh#L67-L75](https://github.com/DSL-UMD/hadoop-calvin/blob/c337680e23ded375df17c09a878f719102a47773/start-build-env.sh#L67-L75)

Also, `docker run --net=host` was added [start-build-env.sh#L87](https://github.com/DSL-UMD/hadoop-calvin/blob/c337680e23ded375df17c09a878f719102a47773/start-build-env.sh#L87) in order to reach the comparable performance for container, which will perform identically to the bare metal.


Now, the following commands could be used to build and start Hadoop dev environment!

```bash
$ cd $project_directory  # where Dockerfile is located

# Build Hadoop Development Environment Docker Image and start it.
$ ./start-build-env.sh

$ docker ps

CONTAINER ID    IMAGE               COMMAND                  CREATED        STATUS       PORTS                    NAMES
a07214073fc3    hadoop-build-501    "/bin/bash"              9 hours ago    Up 9 hours                            hadoop-dev
55eb5cf75643    eg_postgresql       "/usr/lib/postgresql…"   3 weeks ago    Up 9 hours   0.0.0.0:5432->5432/tcp   pg_test

# Jump into container
$ docker exec -it hadoop-dev bash
```

