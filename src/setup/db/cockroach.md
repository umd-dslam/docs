
# Start a Cluster in Docker

## Download CockroachDB Image

If you have not already installed the official CockroachDB Docker image, then you need to pull the image for the `v2.1.6` release of CockroachDB from Docker Hub:

```bash
$ docker pull cockroachdb/cockroach:v2.1.6
```

## Create a Bridge Network

Since you'll be running multiple Docker containers on a single host, with one CockroachDB node per container, you need to create what Docker refers to as a bridge network. The bridge network will enable the containers to communicate as a single cluster while keeping them isolated from external networks.

```bash
$ docker network create -d bridge roachnet
```

## Start the first node

```bash
$ docker run -d \
--name=roach1 \
--hostname=roach1 \
--net=roachnet \
-p 26257:26257 -p 8080:8080  \
-v "${PWD}/cockroach-data/roach1:/cockroach/cockroach-data"  \
cockroachdb/cockroach:v2.1.6 start --insecure
```

> `--hostname`: The hostname for the container. You will use this to join other containers/nodes to the cluster.

## Add nodes to the cluster

With just one node, you can already connect a SQL client and start building out your database. In real deployments, however, you'll always want 3 or more nodes to take advantage of CockroachDB's automatic replication, rebalancing, and fault tolerance capabilities.

To simulate a real deployment, scale your cluster by adding two more nodes:

```bash
$ docker run -d \
--name=roach2 \
--hostname=roach2 \
--net=roachnet \
-v "${PWD}/cockroach-data/roach2:/cockroach/cockroach-data" \
cockroachdb/cockroach:v2.1.6 start --insecure --join=roach1
```

```bash
$ docker run -d \
--name=roach3 \
--hostname=roach3 \
--net=roachnet \
-v "${PWD}/cockroach-data/roach3:/cockroach/cockroach-data" \
cockroachdb/cockroach:v2.1.6 start --insecure --join=roach1
```
> `--join`: This flag joins the new nodes to the cluster, using the first container's hostname. Otherwise, all cockroach start defaults are accepted. Note that since each node is in a unique container, using identical default ports won’t cause conflicts.

## Test the cluster

You can use the `docker exec` command to start the built-in SQL shell in the first container:

```bash
$ docker exec -it roach1 ./cockroach sql --insecure

# Welcome to the cockroach SQL interface.
# All statements must be terminated by a semicolon.
# To exit: CTRL + D.
#
# Server version: CockroachDB CCL v2.1.6 (x86_64-unknown-linux-gnu, built 2019/03/04 23:21:07, go1.10.7) (same version as client)
# Cluster ID: 8a175a56-be36-4136-b3ff-c55cfd177905
#
# Enter \? for a brief introduction.
#
root@:26257/defaultdb> CREATE DATABASE bank;

CREATE DATABASE

Time: 45.2141ms

root@:26257/defaultdb> CREATE TABLE bank.accounts (id INT PRIMARY KEY, balance D 
CREATE TABLE

Time: 49.3003ms

root@:26257/defaultdb> INSERT INTO bank.accounts VALUES (1, 1000.50);
INSERT 1

Time: 80.0553ms

root@:26257/defaultdb> SELECT * FROM bank.accounts;
  id | balance  
+----+---------+
   1 | 1000.50  
(1 row)

Time: 67.3204ms

root@:26257/defaultdb> \q
```

Then start the SQL shell in the second container:

```bash
docker exec -it roach2 ./cockroach sql --insecure

# Welcome to the cockroach SQL interface.
# All statements must be terminated by a semicolon.
# To exit: CTRL + D.
#
# Server version: CockroachDB CCL v2.1.6 (x86_64-unknown-linux-gnu, built 2019/03/04 23:21:07, go1.10.7) (same version as client)
# Cluster ID: 8a175a56-be36-4136-b3ff-c55cfd177905
#
# Enter \? for a brief introduction.
#
root@:26257/defaultdb> SELECT * FROM bank.accounts;
  id | balance  
+----+---------+
   1 | 1000.50  
(1 row)

Time: 33.7007ms

root@:26257/defaultdb> \q
```

## Monitor the cluster

When you started the cockroach docker, you mapped the node's default HTTP port 8080 to port 8080 on the host. Please check out `http://localhost:8080` in your browser!

<img src="https://raw.githubusercontent.com/DSL-UMD/docs/master/src/img/cockroach1.jpeg" class="center" style="width: 100%;" />


<img src="https://raw.githubusercontent.com/DSL-UMD/docs/master/src/img/cockroach2.jpeg" class="center" style="width: 100%;" />


## Create User `docker`

```bash
$ docker exec -it roach2 ./cockroach sql --insecure

$ CREATE USER IF NOT EXISTS docker;
$ GRANT ALL ON DATABASE bank TO docker;
```

## Stop Cockroach DB

```bash
$ docker stop roach1 roach2 roach3
$ docker rm roach1 roach2 roach3
$ rm -rf cockroach-data
```

# References

1. https://www.cockroachlabs.com/docs/stable/install-cockroachdb-mac.html#use-docker-1
2. https://www.cockroachlabs.com/docs/stable/start-a-local-cluster-in-docker.html