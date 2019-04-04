# Rebuild Source Code Optimization 

Compiling Hadoop's entire project is very slow, and a common laptop like Macbook Pro might takes about an hour. For some reason, Maven's incremental compilation has no obvious acceleration. In addition to HDFS, the Hadoop ecosystem includes many subsystems such as [MapReduce](https://hadoop.apache.org/docs/stable/hadoop-mapreduce-client/hadoop-mapreduce-client-core/MapReduceTutorial.html), [Yarn](https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.html), etc.


If you change its source code, in order to speed up the recompiling, we can hack its compilation process as follows:

```bash
$ cd ~/hadoop/hadoop-hdfs-project/hadoop-hdfs-db/
$ mvn package -Pdist -DskipTests
$ cp hadoop-hdfs-db-1.0.0.jar $HADOOP_HOME/share/hadoop/hdfs/lib/
$ cd ~/hadoop/hadoop-hdfs-project/hadoop-hdfs/
$ mvn package -Pdist -DskipTests
$ cp target/hadoop-hdfs-3.3.0-SNAPSHOT.jar $HADOOP_HOME/share/hadoop/hdfs/
$ cp target/hadoop-hdfs-3.3.0-SNAPSHOT-tests.jar $HADOOP_HOME/share/hadoop/hdfs/
```


After you have cleared your last deployment environment, you are ready to start a new deployment.

```bash
$ cd $HADOOP_HOME

$ vim test.sh

# copy the following command lines into test.sh
cd $HADOOP_HOME
rm -rf ~/hadoop/data/*
rm -rf ~/hadoop/name/*
rm -rf ~/hadoop/tmp/*
rm -rf logs/*

PGPASSWORD=docker psql -h localhost -p 5432 -d docker -U docker --command "drop table inodes, inode2block, datablocks, blockstripes, block2storage, storage;"
kill $(jps | grep '[NameNode,DataNode]' | awk '{print $1}')

cd  ~/hadoop
javac HdfsMetaInfoSchema.java
java  HdfsMetaInfoSchema
cd $HADOOP_HOME

./bin/hdfs namenode -format
./sbin/start-dfs.sh


$ bash test.sh
```


