
## Hadoop Baseline

```bash
docker pull gangliao/hdfs_baseline:3.3.0
docker run --rm -it -d  --name hadoop-baseline gangliao/hdfs_baseline:3.3.0
docker exec -it hadoop-baseline bash


cd ..
tar xvf hadoop-3.3.0-SNAPSHOT.tar.gz
cd ~/hadoop-3.3.0-SNAPSHOT
sudo chmod -R 777 /home/gangl/hadoop/
```

```bash
sudo apt-get update
sudo apt-get install -y vim 
sudo apt-get install -y ssh


# vim etc/hadoop/core-site.xml

  <property>
      <name>fs.defaultFS</name>
      <value>hdfs://localhost:9000</value>
  </property>

  <property>
      <name>hadoop.tmp.dir</name>
      <value>/home/gangl/hadoop/tmp</value>
  </property>
  
  
 # vim etc/hadoop/hdfs-site.xml

    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>

    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/home/gangl/hadoop/name</value>
    </property>

    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/home/gangl/hadoop/data</value>
    </property>
    <property>
      <name>dfs.namenode.fs-limits.min-block-size</name>
      <value>10</value>
    </property>
    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
        <description>web permission to acccess HDFS</description>
    </property>
```

```bash
sudo mkdir -p $HOME/hadoop/tmp
sudo mkdir -p $HOME/hadoop/name
sudo mkdir -p $HOME/hadoop/data


mkdir -p ~/.ssh
ssh-keygen -t rsa -f ~/.ssh/id_dsa  
cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys  
chmod 0600 ~/.ssh/authorized_keys
sudo service ssh restart
ssh localhost

# exit ssh
```

```bash
# vim etc/hadoop/hadoop-env.sh

export HADOOP_ROOT_LOGGER=INFO,console
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export DATABASE="VOLT"
```


```bash
 sudo ./bin/hdfs namenode -format
 kill $(jps | grep '[NameNode,DataNode]' | awk '{print $1}')
 # change sbin/start-dfs.sh
 
 ./sbin/start-dfs.sh
 jps
```





