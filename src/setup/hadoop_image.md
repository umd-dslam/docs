
# Build a Hadoop Development Environment Docker Image

## Hadoop Dev Docker Image

Fortunately, official Hadoop team already used Docker as their daily testbed.
We added a few software (**postgresql-client** and **jdbc**) in offical script to access **postgressql-9.3** in the former container (remote server): **pg_test**.


<img src="img/arch01-01.png" class="center" style="width: 70%;" />

<span class="caption">Figure 1-1: The client server architecture diagram of HDFS and Postgres.</span>

These incremental commands are added in [start-build-env.sh#L67-L75](https://github.com/DSL-UMD/hadoop-calvin/blob/c337680e23ded375df17c09a878f719102a47773/start-build-env.sh#L67-L75).

Also, `docker run --net=host` was added [start-build-env.sh#L87](https://github.com/DSL-UMD/hadoop-calvin/blob/c337680e23ded375df17c09a878f719102a47773/start-build-env.sh#L87) in order to reach the comparable performance for container, which will perform identically to the bare metal.


Now, the following commands could be used to build and start Hadoop dev environment! The default container
name is **hadoop-dev**.

```bash
$ cd $project_directory  # where Dockerfile is located

# Build Hadoop Development Environment Docker Image and start it.
$ ./start-build-env.sh

$ docker ps

CONTAINER ID    IMAGE               COMMAND                  CREATED        STATUS       PORTS                    NAMES
a07214073fc3    hadoop-build-501    "/bin/bash"              9 hours ago    Up 9 hours                            hadoop-dev
55eb5cf75643    eg_postgresql       "/usr/lib/postgresql…"   3 weeks ago    Up 9 hours   0.0.0.0:5432->5432/tcp   pg_test
```

## Interact with Postgres

```bash
# Jump into hadoop-dev container
$ docker exec -it hadoop-dev bash

 _   _           _                    ______
| | | |         | |                   |  _  \
| |_| | __ _  __| | ___   ___  _ __   | | | |_____   __
|  _  |/ _` |/ _` |/ _ \ / _ \| '_ \  | | | / _ \ \ / /
| | | | (_| | (_| | (_) | (_) | |_) | | |/ /  __/\ V /
\_| |_/\__,_|\__,_|\___/ \___/| .__/  |___/ \___| \_(_)
                              | |
                              |_|

This is the standard Hadoop Developer build environment.
This has all the right tools installed required to build
Hadoop from source.

# Now, you are in hadoop-dev container!
# see prompt is changed from $ to xxx@linuxkit-025000000001 
xxx@linuxkit-025000000001:~/hadoop$
```

Since we installed **postgresql-client** and **jdbc driver** in hadoop-dev image, 
you can use them to access Postgres's service from remote server (**pg_test** container),
for example, connect to database server, create table and insert/select tuples:

```bash
xxx@linuxkit-025000000001:~/hadoop$ psql -h localhost -p 5432 -d docker -U docker

Password for user docker: # password is docker
SSL connection (protocol: TLSv1.2, cipher: DHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)

docker=# CREATE TABLE cities (name varchar(80), location point);

CREATE TABLE

docker=# INSERT INTO cities VALUES ('San Francisco', '(-194.0, 53.0)');

INSERT 0 1

docker=# SELECT * FROM cities;

     name      | location
---------------+-----------
 San Francisco | (-194,53)
(1 row)
```
