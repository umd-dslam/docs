# Block and BlockInfo

## Block

`Block` is used to uniquely identify data blocks in Namenode and is the most basic abstract interface of the data block in HDFS. Block class defines [three fields](https://github.com/DSL-UMD/hadoop-calvin/blob/c337680e23ded375df17c09a878f719102a47773/hadoop-hdfs-project/hadoop-hdfs-client/src/main/java/org/apache/hadoop/hdfs/protocol/Block.java#L92-L94):

```java
public class Block implements Writable, Comparable<Block> {
    private long blockId;
    private long numBytes;
    private long generationStamp;
    ...
}
```

- **blockId** uniquely identifies this Block object;
- **numBytes** is the size of this data block (in bytes);
- **generationStamp** is the timestamp of this data block.

## BlockInfo

`BlockInfo` extends from Block class and is a supplementary of Block class. For a given block, BlockInfo class maintains BlockCollection and datanodes
where the replicas of the block are stored. [The following fields](https://github.com/DSL-UMD/hadoop-calvin/blob/c337680e23ded375df17c09a878f719102a47773/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/blockmanagement/BlockInfo.java#L41-L64) are the most meaningful to us:

```java
public abstract class BlockInfo extends Block {
    // Replication factor.
    private short replication;
    // Block collection ID.
    private volatile long bcId;
    // Storages this block is replicated on
    protected DatanodeStorageInfo[] storages;
    ...
}
```

- **replication**: If the replication factor was set to 3 (default value in HDFS), there would be one original block and two replicas. For each block stored in HDFS, there will be n – 1 duplicated blocks distributed across the cluster.
- **bcId**: Block collection ID is an alias for INode ID which can uniquely identifies the INode object of the HDFS file through `INodeMap` (see [Section 3.1.1 - FSDirectory](https://dsl-umd.github.io/docs/metadata/inode/fsdirectory.html#fsdirectory)). With this design, both data blocks and inode can easily find each other. For example, FSNameSystem ([FSNamesystem.java#L3640-L3648](https://github.com/DSL-UMD/hadoop-calvin/blob/88528d2ef1ac4926c7716d35ad6c7cd3aa2bc5f0/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/FSNamesystem.java#L3640-L3648)) has a member function `getBlockCollection` to find INode from BlockInfo:

    ```java
    // hadoop/hdfs/server/namenode/FSNamesystem.java
    INodeFile getBlockCollection(BlockInfo b) {
        return getBlockCollection(b.getBlockCollectionId());
    }

    @Override
    public INodeFile getBlockCollection(long id) {
        INode inode = getFSDirectory().getInode(id);
        return inode == null ? null : inode.asFile();
    }
    ```

- **storages** is an array of `DatanodeStorageInfo`. A Datanode has one or more types of storages such as HDD, SSD, RAM, RAID, tape, remote storage (such
as NAS) etc. A storage in the Datanode is represented by this class.

## BlocksMap

