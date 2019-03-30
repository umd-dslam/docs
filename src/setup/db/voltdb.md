# Start a Cluster in Docker

1. Create a directory voltdb-docter:

```bash
$ mkdir voltdb-docker;cd voltdb-docker
```

2. Download VoltDB: http://learn.voltdb.com/DLSoftwareDownload.html

```bash
voltdb-docker>$ ls

voltdb-ent-8.4.2.tar.gz
```

Next, unpack your downloaded VoltDB `tar.gz` file into this directory in a folder named "voltdb-ent".

```bash
voltdb-docker>$ mkdir voltdb-ent
voltdb-docker>$ tar -xzf voltdb-ent-8.4.2.tar.gz
voltdb-docker>$ mv voltdb-ent-8.4.2 voltdb-ent
```

3. Multi-Node Cluster

If we want to use 3 nodes, we're going to add a script that generates a deployment file and starts VoltDB with it. Back in the directory that contains our dockerfile, add this script as a new file named `deploy.py`.

```bash
voltdb-docker>$ cat << EOF > deploy.py
#!/usr/bin/env python

import sys, os

deploymentText = """<?xml version="1.0"?>
<deployment>
    <cluster hostcount="##HOSTCOUNT##" kfactor="##K##" />
    <httpd enabled="true"><jsonapi enabled="true" /></httpd>
</deployment>
"""

deploymentText = deploymentText.replace("##HOSTCOUNT##", sys.argv[1])
deploymentText = deploymentText.replace("##K##", sys.argv[2])

with open('/root/voltdb-ent/deployment.xml', 'w') as f:
    f.write(deploymentText)

os.execv("/root/voltdb-ent/bin/voltdb",
         ["voltdb",
          "create",
          "--deployment=/root/voltdb-ent/deployment.xml",
          "--host=" + sys.argv[3]])
EOF
```

Make `deploy.py` is executable.

```bash
chmod a+x deploy.py
```

4. Create a file named `Dockerfile` in the directory with the following contents:

```bash
voltdb-docker>$ cat << EOF > Dockerfile
# VoltDB on top of Docker base JDK8 images
FROM java:8
WORKDIR /root
COPY voltdb-ent/ voltdb-ent/
COPY deploy.py voltdb-ent/
WORKDIR /root/voltdb-ent
CMD /bin/bash
EOF
```

4. Now build the Docker image:

```bash
voltdb-docker>$ docker build -t gangliao/voltdb:8.4.2 .
```

5. You can find your VoltDB image:

```bash
$ docker image

REPOSITORY            TAG         IMAGE ID            CREATED             SIZE
gangliao/voltdb       8.4.2       d08f1b9a1569        6 minutes ago       773MB
```

6. Now we can start a 1 node (k=0) VoltDB cluster in this way:

```bash
$ docker run --name=volt1 --hostname=volt1 -d -p 8080:8080 \
  gangliao/voltdb:8.4.2 /root/voltdb-ent/deploy.py 3 1 volt1
```

Find the IP of the first container using:

```bash
$ docker inspect --format '{{ .NetworkSettings.IPAddress }}' volt1

172.17.0.3
```

7. we can use that IP as the leader for the second and third nodes:

```bash
$ export LEADERIP=172.17.0.3
$ docker run --name=volt2 --hostname=volt2 -d -p 8081:8080 \
    gangliao/voltdb:8.4.2 /root/voltdb-ent/deploy.py 3 1 $LEADERIP
$ docker run --name=volt3 --hostname=volt3 -d -p 8082:8080 \
    gangliao/voltdb:8.4.2 /root/voltdb-ent/deploy.py 3 1 $LEADERIP

$ docker ps
CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS                    NAMES
a3a4a96b2222        gangliao/voltdb:8.4.2   "/root/voltdb-ent/de…"   3 seconds ago       Up 3 seconds        0.0.0.0:8082->8080/tcp   volt3
75e9b9190ce5        gangliao/voltdb:8.4.2   "/root/voltdb-ent/de…"   12 seconds ago      Up 11 seconds       0.0.0.0:8081->8080/tcp   volt2
015db7c2dccb        gangliao/voltdb:8.4.2   "/root/voltdb-ent/de…"   3 minutes ago       Up 3 minutes        0.0.0.0:8080->8080/tcp   volt1
```

# References

1. https://github.com/VoltDB/voltdb/wiki/Docker-&-VoltDB-Clustering-Intro

