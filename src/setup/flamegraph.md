## HDFS Flame Graph

It is possible to profile Java processes running in a Docker or LXC container both from within a container.

```bash
cd $HADOOP_HOME
git clone https://github.com/jvm-profiling-tools/async-profiler
git clone https://github.com/BrendanGregg/FlameGraph
cd async-profiler && make
cd ../
mkdir async-profiler-output && cd async-profiler-output
# (get hdfs namenode process)
jps
../async-profiler/profiler.sh -t -d 120 -e itimer -o collapsed -f /tmp/collapsed.txt 231591
../FlameGraph/flamegraph.pl  -colors=java /tmp/collapsed.txt > flamegraph_yarn-bigdata40_hdfs_namenode.svg
```

After you execute the above commands in HDFS container, a new `svg` file will be generated!


<a href="https://dsl-umd.github.io/docs/img/flamegraph_hdfs_namenode.svg">
<img src="https://i.imgur.com/gPnUxl2.png" class="center" style="width: 100%;"/>
</a>
