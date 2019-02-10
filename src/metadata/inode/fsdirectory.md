# FSNameSystem

[FSNameSystem](https://github.com/gangliao/hadoop-calvin/blob/36471ed4e9c25a5e92f48f8ff6602309e217cfc4/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/FSNamesystem.java#L325-L352) is a container of both transient and persisted file namespace states, and does all the book-keeping work on a Namenode. Its role is briefly described below:

- The container for BlockManager, DatanodeManager, LeaseManager, etc. services;
- RPC calls that modify or inspect the namespace should get delegated here; 
- Anything that touches only blocks (eg. block reports) is delegated to BlockManager;
- Anything that touches only file information (eg. permissions, mkdirs) is delegated to `FSDirectory`;
- Logs mutations to `FSEditLog`. (FSEditLog already been introduced in [Section 2.1](https://dsl-umd.github.io/docs/intro/hdfs.html#persistence)).


# FSDirectory

[FSDirectory](https://github.com/gangliao/hadoop-calvin/blob/36471ed4e9c25a5e92f48f8ff6602309e217cfc4/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/FSDirectory.java#L98-L106) is a pure in-memory data structure, all of whose operations happen entirely in memory. In contrast, FSNameSystem persists the operations to the disk.

FSDirectory contains two critical members:

- `INodeMap inodeMap` is storing almost all the inodes and maintaining the mapping between `INode ID` and `INode` data structure. (When the majority of fields in one INode are stored in database, the rest will still in memory for now. INode ID in INode can be used to query full fields through combining the result of inodeMap and database to maintain the conformity between database and memory)

- `INodeDirectory rootDir` is the root of in-memory representation of the file/block hierarchy.
