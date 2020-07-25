
# Build a FileScale Development Environment

## FileScale Dev Docker Image


The following commands are used to build and start Hadoop dev environment.

```shell
$ cd $project_directory  # where Dockerfile is located

# Build Hadoop Development Environment Docker Image and start it.
$ ./start-build-env.sh

$ docker ps

CONTAINER ID    IMAGE               COMMAND                  CREATED        STATUS       PORTS                    NAMES
a07214073fc3    hadoop-build-501    "/bin/bash"              9 hours ago    Up 9 hours                            hadoop-dev
```

## Interact with FileScale

```shell
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

Because we installed database drivers in the hadoop-dev image, you allow to directly access FileScale's database layer.
For example, connecting to database server, creating table and inserting tuples:

```shell
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
