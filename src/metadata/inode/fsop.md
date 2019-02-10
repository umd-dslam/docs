# File Operation

`FSDirectory` can perform general operations on any INode via `inodeMap` and `rootDir`.

For example, `nnThroughputBenchmark` is a directory with 10 files:

```bash
nnThroughputBenchmark
└── create
    ├── ThroughputBenchDir0
    │   ├── ThroughputBench0
    │   ├── ThroughputBench1
    │   ├── ThroughputBench2
    │   └── ThroughputBench3
    ├── ThroughputBenchDir1
    │   ├── ThroughputBench4
    │   ├── ThroughputBench5
    │   ├── ThroughputBench6
    │   └── ThroughputBench7
    └── ThroughputBenchDir2
        ├── ThroughputBench8
        └── ThroughputBench9

5 directories, 10 files
```

`nnThroughputBenchmark`, `create`, `ThroughputBenchDir0`, `ThroughputBenchDir1` and `ThroughputBenchDir2` are INodeDirectory. `ThroughputBench[0-9]` are INodeFile. They all exist in memory when HDFS is running.

<img src="https://raw.githubusercontent.com/DSL-UMD/docs/master/src/img/fs-tree.png" class="center" style="width: 80%;" />

<span class="caption">Figure 3-1: File System Namespace in Namenode.</span>

If client wants to delete `ThroughputBench0`, FSDirectory will traverse the directory tree from `nnThroughputBenchmark` to `create` and thence `ThroughputBenchDir0`, then remove the leaf `ThroughputBench0` from its children list.

When Namenode receives more than millions of file operations simultaneously, HDFS are experiencing severe latency due to the limited memory available. Eventually, HDFS is playing a losing game in cloud computing if the scalability bottleneck persists.

