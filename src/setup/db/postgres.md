
# Build a Postgres Docker Image

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

**-p 5432:5432** means pg_test's port 5432 is mapped to the host network port 5432.
pg_test's network port 5432 (Postgres service) is not isolated from the Docker host.


`docker ps` can list all alive containers.

```bash
$ docker ps

CONTAINER ID    IMAGE            COMMAND                  CREATED        STATUS       PORTS                    NAMES
55eb5cf75643    eg_postgresql    "/usr/lib/postgresql…"   3 weeks ago    Up 9 hours   0.0.0.0:5432->5432/tcp   pg_test
```