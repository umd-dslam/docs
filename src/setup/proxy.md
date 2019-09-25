## setup VoltDB's ZK IP and Port

```bash
# Setup zk environment, for simplicity, not necessary
export NNPROXY_ZK_QUORUM="localhost:7181"
export NNPROXY_MOUNT_TABLE_ZKPATH="/hadoop/hdfs/mounts"

export NNPROXY_OPTS="-Ddfs.nnproxy.mount-table.zk.quorum=$NNPROXY_ZK_QUORUM -Ddfs.nnproxy.mount-table.zk.path=$NNPROXY_MOUNT_TABLE_ZKPATH"

```

## Dump Mount table

```bash
./bin/hadoop jar  /home/gangliao/hadoop/hadoop-hdfs-project/hadoop-hdfs-nnproxy/target/hadoop-hdfs-nnproxy-1.0.0.jar org.apache.hadoop.hdfs.nnproxy.tools.DumpMount $NNPROXY_OPTS
```

## Load Mount table

```bash
echo 'hdfs://localhost:9000 /nnThroughputBenchmark/create/ThroughputBenchDir0' > mounts
echo 'hdfs://localhost:9000 /' >> mounts
cat mounts | ./bin/hadoop jar  /home/gangliao/hadoop/hadoop-hdfs-project/hadoop-hdfs-nnproxy/target/hadoop-hdfs-nnproxy-1.0.0.jar org.apache.hadoop.hdfs.nnproxy.tools.LoadMount $NNPROXY_OPTS
```

## Start NNProxy

```bash
./bin/hadoop jar  /home/gangliao/hadoop/hadoop-hdfs-project/hadoop-hdfs-nnproxy/target/hadoop-hdfs-nnproxy-1.0.0.jar org.apache.hadoop.hdfs.nnproxy.server.ProxyMain $NNPROXY_OPTS
```

## Run test

```bash
./bin/hadoop  org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:65212 -op create -threads 1 -files 10      -filesPerDir 100000 -keepResults -logLevel INFO
```
