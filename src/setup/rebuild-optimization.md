# Rebuild Source Code Optimization 

Compiling Hadoop's entire project is very slow, and a common laptop like Macbook Pro might takes about an hour. For some reason, Maven's incremental compilation has no obvious acceleration. In addition to HDFS, the Hadoop ecosystem includes many subsystems such as [MapReduce](https://hadoop.apache.org/docs/stable/hadoop-mapreduce-client/hadoop-mapreduce-client-core/MapReduceTutorial.html), [Yarn](https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.html), etc.


If you change its source code, in order to speed up the recompiling, we can hack its compilation process as follows:

```bash
$ cd ~/hadoop/hadoop-hdfs-project/hadoop-hdfs/
xxx@linuxkit-025000000001:~/.../hadoop-hdfs$ mvn package -Pdist -DskipTests

xxx@linuxkit-025000000001:~/.../hadoop-hdfs$ cp target/hadoop-hdfs-3.3.0-SNAPSHOT.jar $HADOOP_HOME/share/hadoop/hdfs/
xxx@linuxkit-025000000001:~/.../hadoop-hdfs$ cp target/hadoop-hdfs-3.3.0-SNAPSHOT-tests.jar $HADOOP_HOME/share/hadoop/hdfs/
```


After you have cleared your last deployment environment, you are ready to start a new deployment.

```bash
$ cd $HADOOP_HOME

xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ rm -rf ~/hadoop/data/*
xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ rm -rf ~/hadoop/name/*
xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ rm -rf ~/hadoop/tmp/*
xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ rm -rf logs/*

xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ kill $(jps | grep '[NameNode,DataNode]' | awk '{print $1}')

xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ ./bin/hdfs namenode -format

xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ ./sbin/start-dfs.sh
```