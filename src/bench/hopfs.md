
# HopFS

## Setup


### Deploy MySQL Cluster (NDB)

1. First we create an internal Docker network that the containers will use to communicate

  ```bash
  docker network create cluster --subnet=192.168.0.0/16
  ```

2. Then we start the management node

  ```bash
  docker run -d --net=cluster --name=management1 --ip=192.168.0.2 mysql/mysql-cluster ndb_mgmd
  ```
  
3. The two data nodes

  ```bash
  docker run -d --net=cluster --name=ndb1 --ip=192.168.0.3 mysql/mysql-cluster ndbd
  docker run -d --net=cluster --name=ndb2 --ip=192.168.0.4 mysql/mysql-cluster ndbd
  ```

4. And finally the MySQL server node

  ```bash
  docker run -d --net=cluster --name=mysql1 --ip=192.168.0.10 -e MYSQL_RANDOM_ROOT_PASSWORD=true mysql/mysql-cluster mysqld
  ```

The server will be initialized with a randomized password that will need to be changed, so fetch it from the log, then log in and change the password. 

  ```bash
  docker logs mysql1 2>&1 | grep PASSWORD
  docker exec -it mysql1 mysql -uroot -p

  ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyNewPass';
  ```

## References:

1. Salman Niazi, Mahmoud Ismail, Seif Haridi, Jim Dowling, Steffen Grohsschmiedt, and Mikael Ronström. 2017. HopsFS: scaling hierarchical file system metadata using newSQL databases. In Proceedings of the 15th Usenix Conference on File and Storage Technologies (FAST'17). USENIX Association, Berkeley, CA, USA, 89-103.

2. https://github.com/hopshadoop

3. https://hub.docker.com/r/mysql/mysql-cluster
