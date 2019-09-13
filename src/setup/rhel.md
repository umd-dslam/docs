```bash
sudo yum -y install protobuf protobuf-devel cmake
wget http://apache.cs.utah.edu/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz
sudo tar xvf apache-maven-3.6.2-bin.tar.gz -C /usr/lib/

wget https://cmake.org/files/v3.12/cmake-3.12.3.tar.gz
tar zxvf cmake-3.*
cd cmake-3.*
./bootstrap --prefix=/usr/local
make -j$(nproc)
make install
```

```bash
# sudo vim /etc/profile
M2_HOME="/usr/lib/apache-maven-3.6.2"
export M2_HOME

M2="$M2_HOME/bin"
MAVEN_OPTS="-Xms256m -Xmx512m"
export M2 MAVEN_OPTS

PATH=$M2:$PATH
export PATH
```

```bash
mvn clean install -Pdist  -Pnative -DskipTests

mkdir -p $HOME/hadoop/data
mkdir -p $HOME/hadoop/name
mkdir -p $HOME/hadoop/tmp
```

```bash
# vim etc/hadoop/hadoop-env.sh
export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"
export HADOOP_HOME="/home/gangliao/hadoop/hadoop-dist/target/hadoop-3.3.0-SNAPSHOT/"
export HADOOP_HDFS_HOME="/home/gangliao/hadoop/hadoop-dist/target/hadoop-3.3.0-SNAPSHOT/"
export HADOOP_CONF_DIR="/home/gangliao/hadoop/hadoop-dist/target/hadoop-3.3.0-SNAPSHOT/etc/hadoop/"
export CLASSPATH="$CLASSPATH:/home/gangliao/voltadb/voltdb-ent-8.4.2/voltdb/voltdb-8.4.2.jar:/home/gangliao/voltadb/voltdb-ent-8.4.2/voltdb/voltdbclient-8.4.2.jar"
```

```bash
# vim etc/hadoop/core-site.xml

<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>

    <property>
        <name>hadoop.tmp.dir</name>
        <value>/home/gangliao/hadoop/tmp</value>
    </property>
</configuration>

# vim etc/hadoop/hdfs-site.xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>

    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/home/gangliao/hadoop/name</value>
    </property>

    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/home/gangliao/hadoop/data</value>
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
</configuration>
```
