
```docker
docker run -d -p 10800:10800 -p 47500:47500 -p 49112:49112 -p 11211:11211 apacheignite/ignite

cd /hadoop/filescale_init

export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"
export HADOOP_HOME="/home/gangliao/hadoop/hadoop-dist/target/hadoop-3.3.0-SNAPSHOT/"
export HADOOP_HDFS_HOME="/home/gangliao/hadoop/hadoop-dist/target/hadoop-3.3.0-SNAPSHOT/"
export HADOOP_CONF_DIR="/home/gangliao/hadoop/hadoop-dist/target/hadoop-3.3.0-SNAPSHOT/etc/hadoop/"
export CLASSPATH="$CLASSPATH:/home/gangliao/voltadb/voltdb-ent-8.4.2/voltdb/voltdb-8.4.2.jar:/home/gangliao/voltadb/voltdb-ent-8.4.2/voltdb/voltdbclient-8.4.2.jar:/home/gangliao/.ant/lib/ivy.jar:/home/gangliao/ignite-core-2.10.0.jar"
export DATABASE="IGNITE"
export IGNITE_SERVER="172.31.32.188"
```


