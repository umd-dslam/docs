# Rebuild Source Code 

Compiling Hadoop is time-consuming, and we found Maven's incremental compilation has no obvious acceleration. In order to accelerate this process, we can only build the code we changed:

```shell
$ cd $HADOOP_HOME
$ vim build.sh

# copy the following command lines into build.sh
cd ~/hadoop/hadoop-hdfs-project/hadoop-hdfs-db/
mvn install -Pdist -DskipTests
# cp target/hadoop-hdfs-db-1.0.0.jar $HADOOP_HOME/share/hadoop/hdfs/lib/
cd ~/hadoop/hadoop-hdfs-project/hadoop-hdfs/
mvn package -Pdist -DskipTests
cp target/hadoop-hdfs-3.3.0-SNAPSHOT.jar $HADOOP_HOME/share/hadoop/hdfs/
cp target/hadoop-hdfs-3.3.0-SNAPSHOT-tests.jar $HADOOP_HOME/share/hadoop/hdfs/
cd $HADOOP_HOME
```

```shell
bash build.sh
```

After you cleaned the previous build workspace, you are ready to start a new one.

```shell
$ cd $HADOOP_HOME
$ vim test.sh

# copy the following command lines into test.sh
cd $HADOOP_HOME
rm -rf ~/hadoop/data/*
rm -rf ~/hadoop/name/*
rm -rf ~/hadoop/tmp/*
rm -rf logs/*

kill $(jps | grep '[NameNode,DataNode]' | awk '{print $1}')

cd  ~/hadoop
javac HdfsMetaInfoSchema.java
java  HdfsMetaInfoSchema
cd $HADOOP_HOME

./bin/hdfs namenode -format
./sbin/start-dfs.sh
```

```shell
$ bash test.sh
```


