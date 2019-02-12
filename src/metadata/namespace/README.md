# Namespace Management

## INode

INode is a base class containing common fields for file and directory inodes. The following figure shows the class diagram of `INode` in Namespace.
From the class diagram, both `INodeFile` and `INodeDirectory` inherits from the INode class.

<img src="https://raw.githubusercontent.com/DSL-UMD/docs/master/src/img/inode-uml.png" class="center" style="width: 60%;" />

<span class="caption">Figure 1: File and Directory Inheritance.</span>


The attributes in INode ([INode.java#L62](https://github.com/DSL-UMD/hadoop-calvin/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INode.java#L62), [INodeWithAdditionalFields.java#L98-L124](https://github.com/DSL-UMD/hadoop-calvin/blob/6c852f2a3757129491c21a9ba3b315a7a00c0c28/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INodeWithAdditionalFields.java#L98-L124)), INodeFile ([INodeFile.java#L251-L253](https://github.com/DSL-UMD/hadoop-calvin/blob/6c852f2a3757129491c21a9ba3b315a7a00c0c28/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INodeFile.java#L251-L253)) and INodeDirectory ([INodeDirectory.java#L74](https://github.com/DSL-UMD/hadoop-calvin/blob/6c852f2a3757129491c21a9ba3b315a7a00c0c28/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INodeDirectory.java#L74)) are defined as follows:

**Note:** You can only see these attributes at `truck` branch of our github repo: [DSL-UMD/hadoop-calvin](https://github.com/DSL-UMD/hadoop-calvin), since the default branch `calvin` removed them into database.


```java
public abstract class INode implements INodeAttributes, Diff.Element<byte[]> { {
    long parent;
}

public abstract class INodeWithAdditionalFields extends INode {
  final private long id;
  private byte[] name = null;
  private long permission = 0L;
  private long modificationTime = 0L;
  private long accessTime = 0L;

  /** For implementing {@link LinkedElement}. */
  private LinkedElement next = null;
  /** An array {@link Feature}s. */
  private static final Feature[] EMPTY_FEATURE = new Feature[0];
  protected Feature[] features = EMPTY_FEATURE;
}

public class INodeDirectory extends INodeWithAdditionalFields
    implements INodeDirectoryAttributes {
    List<INode> children;   // INode's children list
}

public class INodeFile extends INodeWithAdditionalFields
    implements INodeFileAttributes, BlockCollection {
   long header;
   BlockInfo[] blocks;
}
```

- **id**: The inode id;
- **parent**: The parent inode id;
- **name**: The inode name is in java UTF8 encoding;
- **permission**: Permission encoded using [PermissionStatusFormat](https://github.com/DSL-UMD/hadoop-calvin/blob/6c852f2a3757129491c21a9ba3b315a7a00c0c28/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INodeWithAdditionalFields.java#L39-L41) where the 64-bit format represents 16-bit mode, 24-bit group and 24-bit user;
- **modificationTime**: The last modification time;
- **accessTime**: The last access time;
- **children**: directory's children list;
- **header**: Storage policy encoded using [HeaderFormat](https://github.com/DSL-UMD/hadoop-calvin/blob/6c852f2a3757129491c21a9ba3b315a7a00c0c28/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INodeFile.java#L95-L123) where the 64-bit format represents 4-bit storagePolicyID, 12-bit BLOCK_LAYOUT_AND_REDUNDANCY and 48-bit preferredBlockSize;
- **blocks**: BlockInfo maintains where the replicas of the block are stored. More details can be found in [Section 3.2.2 Block and BlockInfo](https://dsl-umd.github.io/docs/metadata/datablock/2.blockinfo.html).


 The directory is represented by the INodeDirectory object in memory, and `List<INode> children` is used to describe subdirectories or files in the directory; File is represented by the INodeFile object in memory, and `BlockInfo[] blocks` is used to indicate which blocks of the file are composed.


In [Section 3.4.2 - Data Model](https://dsl-umd.github.io/docs/metadata/datamodel/2.crud.html), We will store all their attributes into database system and replace the corresponding functions with our database-based implementation.


## File Operation

When clients send requests for file operations (mkdir, create, open, rename, delete) through [ClientProtocol](https://github.com/gangliao/hadoop-calvin/blob/36471ed4e9c25a5e92f48f8ff6602309e217cfc4/hadoop-hdfs-project/hadoop-hdfs-client/src/main/java/org/apache/hadoop/hdfs/protocol/ClientProtocol.java#L63-L68)'s RPCs, after Namenode receives requests from clients, it will forward them to the `FSNameSystem` and `FSDirectory` to proceed. Both of them are managing the state of the namespace.


### FSNameSystem

[FSNameSystem](https://github.com/gangliao/hadoop-calvin/blob/36471ed4e9c25a5e92f48f8ff6602309e217cfc4/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/FSNamesystem.java#L325-L352) is a container of both transient and persisted file namespace states, and does all the book-keeping work on a Namenode. Its role is briefly described below:

- The container for BlockManager, DatanodeManager, LeaseManager, etc. services;
- RPC calls that modify or inspect the namespace should get delegated here; 
- Anything that touches only blocks (eg. block reports) is delegated to BlockManager;
- Anything that touches only file information (eg. permissions, mkdirs) is delegated to `FSDirectory`;
- Logs mutations to `FSEditLog`. (FSEditLog already been introduced in [Section 2.1](https://dsl-umd.github.io/docs/intro/hdfs.html#persistence)).


### FSDirectory

[FSDirectory](https://github.com/gangliao/hadoop-calvin/blob/36471ed4e9c25a5e92f48f8ff6602309e217cfc4/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/FSDirectory.java#L98-L106) is a pure in-memory data structure, all of whose operations happen entirely in memory. In contrast, FSNameSystem persists the operations to the disk.

FSDirectory contains two critical members:

- `INodeMap inodeMap` is storing almost all the inodes and maintaining the mapping between `INode ID` and `INode` data structure. (When the majority of fields in one INode are stored in database, the rest will still in memory for now. INode ID in INode can be used to query full fields through combining the result of inodeMap and database to maintain the conformity between database and memory)

- `INodeDirectory rootDir` is the root of in-memory representation of the file/block hierarchy.


### Operations

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

<span class="caption">Figure 1: File System Namespace in Namenode.</span>

If client wants to delete `ThroughputBench0`, FSDirectory will traverse the directory tree from `nnThroughputBenchmark` to `create` and thence `ThroughputBenchDir0`, then remove the leaf `ThroughputBench0` from its children list.

When the Namenode maintains billions of files, HDFS are experiencing severe latency or even crashes due to the limited memory available. Eventually, HDFS is playing a losing game in cloud computing if the scalability bottleneck persists.  

