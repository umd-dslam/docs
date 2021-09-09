# FileScale Benchmark

HDFS NNThroughputBenchmark is a name-node throughput benchmark, which runs a series of client threads on a single node against a name-node. If no name-node is configured, it will firstly start a name-node in the same process (standalone mode), in which case each client repetitively performs the same operation by directly calling the respective name-node methods. Otherwise, the benchmark will perform the operations against a remote name-node via client protocol RPCs (remote mode). Either way, all clients are running locally in a single process rather than remotely across different nodes. The reason is to avoid communication overhead caused by RPC connections and serialization, and thus reveal the upper bound of pure name-node performance.  we extended the client workload generation in the benchmark codebase to run inthe large-scale environments required for our analysis.

More details can be found [here](https://hadoop.apache.org/docs/r3.2.0/hadoop-project-dist/hadoop-common/Benchmarking.html).


Please adjust the command line parameters by yourself:

### Create

```shell
$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op create -threads 1 -files 2 -filesPerDir 1000 -keepResults -logLevel INFO
```

### Open

```shell
$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op Open -threads 1 -files 2 -filesPerDir 1000 -keepResults -logLevel INFO
```

### Delete

```shell
$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op delete -threads 1 -files 2 -filesPerDir 1000 -keepResults -logLevel INFO
```

### Mkdirs

```shell
$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op mkdirs -threads 1 -dirs 2 -dirsPerDir 1000 -keepResults -logLevel INFO
```

### Rename

```shell
$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op rename -threads 1 -files 2 -filesPerDir 1000 -keepResults -logLevel INFO
```

### Clean

```shell
$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op clean -keepResults -logLevel INFO
```

### Rename Directory

```shell
$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op create -threads 1 -files 2 -filesPerDir 1000 -keepResults -logLevel INFO
$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op renameDir -keepResults -logLevel INFO
```

### Chmod

```shell
./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -op chmodDir  -logLevel INFO &
```
