# INode Metadata

When clients send requests for file operations (mkdir, create, open, rename, delete) through [ClientProtocol](https://github.com/gangliao/hadoop-calvin/blob/36471ed4e9c25a5e92f48f8ff6602309e217cfc4/hadoop-hdfs-project/hadoop-hdfs-client/src/main/java/org/apache/hadoop/hdfs/protocol/ClientProtocol.java#L63-L68)'s RPCs, after Namenode receives requests from clients, it will forward them to the `FSNameSystem` and `FSDirectory` to proceed. Both of them are managing the state of the namespace.

## FSNameSystem

[FSNameSystem](https://github.com/gangliao/hadoop-calvin/blob/36471ed4e9c25a5e92f48f8ff6602309e217cfc4/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/FSNamesystem.java#L325-L352) is a container of both transient and persisted file namespace states, and does all the book-keeping work on a Namenode. Its role is briefly described below:

- The container for BlockManager, DatanodeManager, LeaseManager, etc. services;
- RPC calls that modify or inspect the namespace should get delegated here; 
- Anything that touches only blocks (eg. block reports) is delegated to `BlockManager`;
- Anything that touches only file information (eg. permissions, mkdirs) is delegated to `FSDirectory`.
- Logs mutations to `FSEditLog`. (`FSEditLog` already been introduced in [Section 2.1](https://dsl-umd.github.io/docs/intro/hdfs.html#persistence)).


## FSDirectory

[FSDirectory](https://github.com/gangliao/hadoop-calvin/blob/36471ed4e9c25a5e92f48f8ff6602309e217cfc4/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/FSDirectory.java#L98-L106) is a pure in-memory data structure, all of whose operations happen entirely in memory. In contrast, `FSNameSystem` persists the operations to the disk.

`FSDirectory` contains two critical members:

- `INodeMap inodeMap` is storing almost all the inodes and maintaining the mapping between `INode ID` and `INode` data structure. (When the majority of fields in one `INode` are stored in database, the rest will still in memory for now. INode ID in `INode` can be used to query full fields through combining the result of `inodeMap` and database to maintain the conformity between database and memory)

- `INodeDirectory rootDir` is the root of in-memory representation of the file/block hierarchy.

### INode

`INode` above is a base class containing common fields for file and directory inodes. The relationships among `INode` ([INode.java#L62](https://github.com/DSL-UMD/hadoop-calvin/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INode.java#L62), [INodeWithAdditionalFields.java#L98-L124](https://github.com/DSL-UMD/hadoop-calvin/blob/6c852f2a3757129491c21a9ba3b315a7a00c0c28/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INodeWithAdditionalFields.java#L98-L124)), `INodeFile` ([INodeFile.java#L251-L253](https://github.com/DSL-UMD/hadoop-calvin/blob/6c852f2a3757129491c21a9ba3b315a7a00c0c28/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INodeFile.java#L251-L253)) and `INodeDirectory` ([INodeDirectory.java#L74](https://github.com/DSL-UMD/hadoop-calvin/blob/6c852f2a3757129491c21a9ba3b315a7a00c0c28/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INodeDirectory.java#L74)) are defined as follows:

**Note:** You can only see these fields at `truck` branch of our github repo: [DSL-UMD/hadoop-calvin](https://github.com/DSL-UMD/hadoop-calvin), since the default branch `calvin` removed them into database.


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
   BlockInfo[] blocks;
   ...
}
```

Briefly speaking, the three different classes are based on `INode` class and we will store almost all the attributes here into database system and replace the corresponding functions with our database-based implementation.

### File Operation

`FSDirectory` can perform general operations on any `INode` via `inodeMap` and `rootDir`.

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

`nnThroughputBenchmark`, `create`, `ThroughputBenchDir0`, `ThroughputBenchDir1` and `ThroughputBenchDir2` are `INodeDirectory`. `ThroughputBench[0-9]` are `INodeFile`. They all exist in memory when HDFS is running.

<img src="https://raw.githubusercontent.com/DSL-UMD/docs/master/src/img/fs-tree.png" class="center" style="width: 80%;" />

<span class="caption">Figure 3-1: File System Namespace in Namenode.</span>


If client wants to delete `ThroughputBench0`, `FSDirectory` will traverse the directory tree from `nnThroughputBenchmark` to `create` and thence `ThroughputBenchDir0`, then remove the leaf `ThroughputBench0` from its children list.

When Namenode receives more than millions of file operations simultaneously, HDFS are experiencing severe latency due to the limited memory available. Eventually, HDFS is playing a losing game in cloud computing if the scalability bottleneck persists.

## Data Model

In order to unlock the memory bottleneck of namenode, we propose to replace file metadata in memory with a deterministic distributed system which can improve scalability of the file system, as file metadata can be partitioned across a shared-nothing cluster of independent servers.

Singleton pattern is used to restrict the instance of [DatabaseConnection](https://github.com/DSL-UMD/hadoop-calvin/blob/calvin/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/DatabaseConnection.java) class to one object. This is useful when exactly one object is needed to coordinate actions across the system. The generic metadata storage layer we implemented can easily enable a different database to be plugged into HDFS. In this project, in order to keep it simple, we first integrate **Postgres** into HDFS to demonstrate how it works. Then, deterministic database systems like **Calvin** or **FaunaDB** can be considered as a backend later.

### Tables

We already replace fields such as **id**, **parent**, **name**, **accessTime**, **modificationTime**, **permission** and **header** with `inodes table` in Postgres. All related get/set inode functions have been modified to support database. For example, 

```java
public long getPermissionLong() {
    return this.permission;
}
private final void setPermission(long permission) {
    this.permission = permission;
}
```

has been changed to

```java
public long getPermissionLong() {
    return DatabaseConnection.getPermission(this.getId());
}
private final void setPermission(long permission) {
    DatabaseConnection.setPermission(this.getId(), permission);
}
```

#### Create 

When `DatabaseConnection.getInstance()` is invoked, Object will be initialized by its constructor (only once in the lifetime of the file system), and `inodes` table also will be
created.

```sql
DROP TABLE IF EXISTS inodes;
CREATE TABLE inodes(
    id int primary key, parent int, name text,
    accessTime bigint, modificationTime bigint,
    header bigint, permission bigint
);
```

#### Insert

Inserting a new inode into database is tricky. Most of the fields such as **id**, **name**, **accessTime**, **modificationTime**, **permission** are assigned during the initialization of `INodeFile` and `INodeDirectory`. However, the rest like **header** and **parent** are updated during the runtime of file operations. Therefore, at least two SQL statements are required in here.

```sql
INSERT INTO inodes(
    id, name, accessTime, modificationTime, permission
) VALUES (?, ?, ?, ?, ?);

UPDATE inodes SET parent = ?, name = ? WHERE id = ?;
```