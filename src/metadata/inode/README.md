# INode Metadata

When clients send requests for file operations (mkdir, create, open, rename, delete) through [ClientProtocol](https://github.com/gangliao/hadoop-calvin/blob/36471ed4e9c25a5e92f48f8ff6602309e217cfc4/hadoop-hdfs-project/hadoop-hdfs-client/src/main/java/org/apache/hadoop/hdfs/protocol/ClientProtocol.java#L63-L68)'s RPCs, after Namenode receives requests from clients, it will forward them to the `FSNameSystem` to proceed.

Both `FSDirectory` and `FSNamesystem` manage the state of the namespace.

## FSNameSystem

[FSNameSystem]((https://github.com/gangliao/hadoop-calvin/blob/36471ed4e9c25a5e92f48f8ff6602309e217cfc4/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/FSNamesystem.java#L325-L352) is a container of both transient and persisted file namespace states, and does all the book-keeping work on a Namenode. Its role is briefly described below:

- The container for BlockManager, DatanodeManager, LeaseManager, etc. services;
- RPC calls that modify or inspect the namespace should get delegated here; 
- Anything that touches only blocks (eg. block reports) is delegated to `BlockManager`;
- Anything that touches only file information (eg. permissions, mkdirs) is delegated to `FSDirectory`.
- Logs mutations to `FSEditLog`. (`FSEditLog` already been introduced in [Section 2.1](https://dsl-umd.github.io/docs/intro/hdfs.html#persistence)).


## FSDirectory

[FSDirectory](https://github.com/gangliao/hadoop-calvin/blob/36471ed4e9c25a5e92f48f8ff6602309e217cfc4/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/FSDirectory.java#L98-L106) is a pure in-memory data structure, all of whose operations happen entirely in memory. In contrast, `FSNameSystem` persists the operations to the disk.

`FSDirectory` contains two critical members:

- `INodeMap inodeMap` is storing almost all the inodes and maintaining the mapping between `INode ID` and `INode` data structure. (When the majority of fields in one `INode` are stored in database, the rest will still in memory for now. `INode ID` in `INode` can be used to query full fields through combining the result of `inodeMap` and database to maintain the conformity between database and memory)

- `INodeDirectory rootDir` is the root of in-memory representation of the file/block hierarchy.

`FSDirectory` can perform general operations on any `INode` via `inodeMap` and `rootDir`.

For example, if we have a directory `nnThroughputBenchmark` with 10 files:

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

4 directories, 10 files
```


## INode

`INode` above is a base class containing common fields for file and directory inodes. The relationships among `INode`, `INodeFile` and `INodeDirectory` are defined as follows:


```java
INode {
    long id;                // INode identifier
    byte[] name;            // stored as varchar in database
    long parent;            // INode's parent identifer
    long accessTime;        // access time
    long modificationTime;  // modification time
    long permission;        // 64bit=mode(16)+group(24)+user(24)
    LinkedElement next;
    Feature[] features;
    ...
}

INodeDirectory extends INode {
    List<INode> children;   // INode's children list
    ...
}

INodeFile extends INode {
   // header = 64 bits = storagePolicy(4)
   //                  + BLOCK_LAYOUT_AND_REDUNDANCY(12)
   //                  + preferredBlockSize(48)
   long header;
   BlockInfo[] blklist;
   ...
}
```

