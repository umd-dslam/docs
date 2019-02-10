# INode

INode is a base class containing common fields for file and directory inodes. The relationships among INode ([INode.java#L62](https://github.com/DSL-UMD/hadoop-calvin/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INode.java#L62), [INodeWithAdditionalFields.java#L98-L124](https://github.com/DSL-UMD/hadoop-calvin/blob/6c852f2a3757129491c21a9ba3b315a7a00c0c28/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INodeWithAdditionalFields.java#L98-L124)), INodeFile ([INodeFile.java#L251-L253](https://github.com/DSL-UMD/hadoop-calvin/blob/6c852f2a3757129491c21a9ba3b315a7a00c0c28/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INodeFile.java#L251-L253)) and INodeDirectory ([INodeDirectory.java#L74](https://github.com/DSL-UMD/hadoop-calvin/blob/6c852f2a3757129491c21a9ba3b315a7a00c0c28/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INodeDirectory.java#L74)) are defined as follows:

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

Briefly speaking, both `INodeFile` and `INodeDirectory` inherit from `INode` class. We will store almost all their attributes into database system and replace the corresponding functions with our database-based implementation.
