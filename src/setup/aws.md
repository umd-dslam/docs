

```bash
echo 'hdfs://ip-172-30-0-250.ec2.internal:9000 /nnThroughputBenchmark/create/ThroughputBenchDir0' > mounts
echo 'hdfs://ip-172-30-0-250.ec2.internal:9000 /' >> mounts
cat mounts | ./bin/hadoop jar /home/ec2-user/voltfs/hadoop-hdfs-nnproxy-1.0.0.jar org.apache.hadoop.hdfs.nnproxy.tools.LoadMount $NNPROXY_OPTS
./bin/hadoop jar  /home/ec2-user/voltfs/hadoop-hdfs-nnproxy-1.0.0.jar org.apache.hadoop.hdfs.nnproxy.tools.DumpMount $NNPROXY_OPTS
./bin/hadoop jar  /home/ec2-user/voltfs/hadoop-hdfs-nnproxy-1.0.0.jar org.apache.hadoop.hdfs.nnproxy.server.ProxyMain $NNPROXY_OPTS &

./bin/hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://ip-172-30-0-44.ec2.internal:65212 -op create -threads 1 -files 10000 -filesPerDir 1000000 -logLevel INFO
```
