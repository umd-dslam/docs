
# HopFS

## Setup


### Deploy MySQL Cluster (NDB)

1. First we create an internal Docker network that the containers will use to communicate

```bash
docker network create cluster --subnet=192.168.0.0/16
```

2. Then we start the management node

```bash
docker run -d --net=cluster --name=management1 --ip=192.168.0.2 -p 1186:1186 mysql/mysql-cluster ndb_mgmd
```
  
3. The two data nodes

```bash
docker run -d --net=cluster --name=ndb1 --ip=192.168.0.3 mysql/mysql-cluster ndbd
docker run -d --net=cluster --name=ndb2 --ip=192.168.0.4 mysql/mysql-cluster ndbd
```

4. And finally the MySQL server node

```bash
docker run -d --net=cluster --name=mysql1 --ip=192.168.0.10 -p 3307:3306 -e MYSQL_ALLOW_EMPTY_PASSWORD=true -e MYSQL_DATABASE=metadb mysql/mysql-cluster mysqld
```

The server will be initialized and then you can log in without password. 

```bash
docker exec -it mysql1 mysql -uroot -p
```

5. Access MySQL cluster from Host

```bash
brew install mysql-client # mac osx
mysql -u root -h localhost -P 3307 --protocol=tcp
```


## RUN

```bash
cp ~/hopfs/libndbclient.so* /home/gangl/hopfs/hops/hadoop-dist/target/hadoop-2.8.2.9-SNAPSHOT/lib/native
cp ~/hopfs/clusterj-* share/hadoop/common/lib/
```

## References:

1. Salman Niazi, Mahmoud Ismail, Seif Haridi, Jim Dowling, Steffen Grohsschmiedt, and Mikael Ronström. 2017. HopsFS: scaling hierarchical file system metadata using newSQL databases. In Proceedings of the 15th Usenix Conference on File and Storage Technologies (FAST'17). USENIX Association, Berkeley, CA, USA, 89-103.

2. https://github.com/hopshadoop

3. https://hub.docker.com/r/mysql/mysql-cluster
