# Heterogeneous Storage

Each DataNode in a cluster is configured with a set of data directories. You can configure each data directory with a storage type.
The storage policy dictates which storage types to use when storing the file or directory. There are some reasons to consider using different types of storage: 

- You have datasets with temporal locality. The latest data can be loaded initially into SSD for improved performance, then migrated out to disk as it ages;
- You need to move cold data to denser archival storage because the data will rarely be accessed and archival storage is much cheaper. Storage systems like Facebook's f4 [2] also used a similar idea to provide low latency and sufficient throughput.

## DatanodeStorageInfo

As shown in the former [Section 3.2.2](https://dsl-umd.github.io/docs/metadata/datablock/blockinfo.html#blockinfo), [BlockInfo.storages](https://github.com/DSL-UMD/hadoop-calvin/blob/c337680e23ded375df17c09a878f719102a47773/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/blockmanagement/BlockInfo.java#L62) is an array of DatanodeStorageInfo. A storage in the Datanode is represented by DatanodeStorageInfo. 
A Datanode has one or more types of storages such as HDD, SSD, RAM, and so on.  HDFS distinguishes different storage types and hence applications can  selectively use storage media with different performance characteristics.

`DatanodeStorageInfo` class contains many variables, we only introduce the most relevant ones, but you can check out [DatanodeStorageInfo.java#L90-L120](https://github.com/DSL-UMD/hadoop-calvin/blob/88528d2ef1ac4926c7716d35ad6c7cd3aa2bc5f0/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/blockmanagement/DatanodeStorageInfo.java#L90-L120) for more information.

```java
public class DatanodeStorageInfo {
    private final DatanodeDescriptor dn;
    private final String storageID;
    private StorageType storageType;
    private State state;

    private long capacity;

    /** The number of block reports received */
    private int blockReportCount = 0;
    ...
}
```

- **storageID**

## DatanodeDescriptor



## References

1. Heterogeneous Storage for HDFS: [https://issues.apache.org/jira/browse/HDFS-2832](https://issues.apache.org/jira/browse/HDFS-2832)

2. Subramanian Muralidhar, Wyatt Lloyd, Sabyasachi Roy, Cory Hill, Ernest Lin, Weiwen Liu, Satadru Pan, Shiva Shankar, Viswanath Sivakumar, Linpeng Tang, and Sanjeev Kumar. 2014. f4: Facebook's warm BLOB storage system. In Proceedings of the 11th USENIX conference on Operating Systems Design and Implementation (OSDI'14). USENIX Association, Berkeley, CA, USA, 383-398.