## setup VoltDB's ZK IP and Port

```shell
# Setup zk environment, for simplicity, not necessary
export NNPROXY_ZK_QUORUM="localhost:7181"
export NNPROXY_MOUNT_TABLE_ZKPATH="/hadoop/hdfs/mounts"

export NNPROXY_OPTS="-Ddfs.nnproxy.mount-table.zk.quorum=$NNPROXY_ZK_QUORUM -Ddfs.nnproxy.mount-table.zk.path=$NNPROXY_MOUNT_TABLE_ZKPATH"

```

## Load Mount table

```shell
echo 'hdfs://localhost:9000 /nnThroughputBenchmark/create/ThroughputBenchDir0' > mounts
echo 'hdfs://localhost:9000 /' >> mounts
cat mounts | ./bin/hadoop org.apache.hadoop.hdfs.nnproxy.tools.LoadMount $NNPROXY_OPTS
```

## Dump Mount table

```shell
./bin/hadoop org.apache.hadoop.hdfs.nnproxy.tools.DumpMount $NNPROXY_OPTS
```



## Start NNProxy

```shell
./bin/hadoop org.apache.hadoop.hdfs.nnproxy.server.ProxyMain $NNPROXY_OPTS
```

## Run test

```shell
./bin/hadoop  org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:65212 -op create -threads 1 -files 10      -filesPerDir 100000 -keepResults -logLevel INFO
```

## FAQ

```python
os.execv("/root/voltdb/voltdb-ent/bin/voltdb",
         ["voltdb",
          "create",
          "--deployment=/root/voltdb/deployment.xml",
                    "--host=" + sys.argv[3],
          "--zookeeper=0.0.0.0:7181"])
```
