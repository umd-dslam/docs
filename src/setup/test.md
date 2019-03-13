# HDFS Namenode Test

HDFS NNThroughputBenchmark is a name-node throughput benchmark, which runs a series of client threads on a single node against a name-node. If no name-node is configured, it will firstly start a name-node in the same process (standalone mode), in which case each client repetitively performs the same operation by directly calling the respective name-node methods. Otherwise, the benchmark will perform the operations against a remote name-node via client protocol RPCs (remote mode). Either way, all clients are running locally in a single process rather than remotely across different nodes. The reason is to avoid communication overhead caused by RPC connections and serialization, and thus reveal the upper bound of pure name-node performance.

More details can be found [here](https://hadoop.apache.org/docs/r3.2.0/hadoop-project-dist/hadoop-common/Benchmarking.html).


Please adjust the command line parameters by yourself:

```bash
# open *
xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op open -threads 1 -files 100000 -keepResults -logLevel INFO

# open  *
xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op open -threads 100 -files 100 -keepResults -logLevel INFO

# create *
xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op create -threads 1 -files 2 -keepResults -logLevel INFO

# delete *
xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op delete -threads 1 -files 10 -keepResults -logLevel INFO

# mkdirs *
xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op mkdirs -threads 1 -dirs 10 -keepResults -logLevel INFO

# blockreport *
xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$  ./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://localhost:9000 -op blockReport -datanodes 3 -reports 3 -blocksPerReport 3 -blocksPerFile 3 -keepResults -logLevel INFO
```

