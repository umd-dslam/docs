# Datanode Management

Each DataNode in a cluster is configured with a set of data directories. You can configure each data directory with a storage type.
The storage policy dictates which storage types to use when storing the file or directory. There are some reasons to consider using different types of storage: 

- You have datasets with temporal locality. The latest data can be loaded initially into SSD for improved performance, then migrated out to disk as it ages;
- You need to move cold data to denser archival storage because the data will rarely be accessed and archival storage is much cheaper. Storage systems like Facebook's f4 [2] also used a similar idea to provide low latency and sufficient throughput.

## DatanodeStorageInfo

As shown in the former [Section 3.2](https://dsl-umd.github.io/docs/metadata/datablock/index.html), [BlockInfo.storages](https://github.com/DSL-UMD/hadoop-calvin/blob/c337680e23ded375df17c09a878f719102a47773/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/blockmanagement/BlockInfo.java#L62) is an array of `DatanodeStorageInfo`. A storage in Datanode is represented by DatanodeStorageInfo.
A Datanode has one or more types of storages such as HDD, SSD, RAM, and so on. Each Datanode must be treated as a collection of storages. HDFS distinguishes different storage types and hence applications can selectively use storage media with different performance characteristics. Awareness of storage media can allow HDFS to make better decisions about the placement of block data with input from applications. An application can choose the distribution of replicas based on its performance and durability requirements.

`DatanodeStorageInfo` class contains many variables, we only introduce the most relevant ones, but you can check out [[DatanodeStorageInfo.java#L90-L120](https://github.com/DSL-UMD/hadoop-calvin/blob/88528d2ef1ac4926c7716d35ad6c7cd3aa2bc5f0/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/blockmanagement/DatanodeStorageInfo.java#L90-L120)] for more information.

```java
public class DatanodeStorageInfo {
    private final DatanodeDescriptor dn;
    private final String storageID;
    private StorageType storageType;
    private long capacity;
    private int blockReportCount = 0;
    ...
}
```

- **storageID** identifies a single storage directory/volume used for storing blocks;

- [storageType](https://github.com/DSL-UMD/hadoop-calvin/blob/88528d2ef1ac4926c7716d35ad6c7cd3aa2bc5f0/hadoop-common-project/hadoop-common/src/main/java/org/apache/hadoop/fs/StorageType.java#L29-L41) identifies the underlying storage media. The default storage medium is assumed to be DISK;
    - `ARCHIVE`: Archival storage is for very dense storage and is useful for rarely accessed data. This storage type is typically cheaper per TB than normal hard disks.
    - `DISK`: Hard disk drives are relatively inexpensive and provide sequential I/O performance. This is the default storage type.
    - `SSD`: Solid state drives are useful for storing hot data and I/O-intensive applications.
    - `RAM_DISK`: This special in-memory storage type is used to accelerate low-durability, single-replica writes.

- **capacity**: This storage volume's capacity;

- **blockReportCount**: The number of block reports received from the Datanode.

- **DatanodeDescriptor dn**:  This class extends the DatanodeInfo class with **ephemeral** information (e.g. health, capacity, what blocks are associated with the Datanode) that is private to the Namenode, i.e. this class is not exposed to clients.

## DatanodeDescriptor

`DatanodeDescriptor` tracks stats on a given datanode, such as available storage capacity, last update time, etc., and maintains a set of blocks stored on the datanode. This data structure is a data structure that is internal to the namenode. It is not sent over-the-wire to the Client or the Datanodes.
Neither is it stored persistently in the `FSImage`.

In this project, all fields of DatanodeDescriptor will be stored into the database system. We only introduce a few special fields here, more details can be found in [[DatanodeDescriptor.java#L150-L232](https://github.com/DSL-UMD/hadoop-calvin/blob/c337680e23ded375df17c09a878f719102a47773/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/blockmanagement/DatanodeDescriptor.java#L150-L232), [DatanodeID.java#L42-L65](https://github.com/DSL-UMD/hadoop-calvin/blob/c337680e23ded375df17c09a878f719102a47773/hadoop-hdfs-project/hadoop-hdfs-client/src/main/java/org/apache/hadoop/hdfs/protocol/DatanodeID.java#L42-L65)].

`DatanodeDescriptor` extends from `DatanodeInfo` which extends from `DatanodeID`:

```java
public class DatanodeID implements Comparable<DatanodeID> {
    private String ipAddr;            // IP address
    private ByteString ipAddrBytes;   // ipAddr ByteString to save on PB serde
    private String hostName;          // hostname claimed by datanode
    private ByteString hostNameBytes; // hostName ByteString to save on PB serde
    private String peerHostName;      // hostname from the actual connection
    private int xferPort;             // data streaming port
    private int infoPort;             // info server port
    private int infoSecurePort;       // info server port
    private int ipcPort;              // IPC server port
    private String xferAddr;
    /**
    * UUID identifying a given datanode. For upgraded Datanodes this is the
    * same as the StorageID that was previously used by this Datanode.
    * For newly formatted Datanodes it is a UUID.
    */
    private final String datanodeUuid;
    // datanodeUuid ByteString to save on PB serde
    private final ByteString datanodeUuidBytes;
    ...
}

/**
 * This class extends the primary identifier of a Datanode with ephemeral
 * state, eg usage information, current administrative state, and the
 * network location that is communicated to clients.
 */
public class DatanodeInfo extends DatanodeID implements Node {
    private long capacity;
    private long dfsUsed;
    private long nonDfsUsed;
    private long remaining;
    private long blockPoolUsed;
    private long cacheCapacity;
    private long cacheUsed;
    private long lastUpdate;
    private long lastUpdateMonotonic;
    private int xceiverCount;
    private volatile String location = NetworkTopology.DEFAULT_RACK;
    private String softwareVersion;
    private List<String> dependentHostNames = new LinkedList<>();
    private String upgradeDomain;
    private int numBlocks;
    ...
}

public class DatanodeDescriptor extends DatanodeInfo {
    protected final Map<String, DatanodeStorageInfo> storageMap = new HashMap<>();

    /** A queue of blocks to be replicated by this datanode */
    private final BlockQueue<BlockTargetPair> replicateBlocks =
        new BlockQueue<>();
    /** A queue of blocks to be erasure coded by this datanode */
    private final BlockQueue<BlockECReconstructionInfo> erasurecodeBlocks =
        new BlockQueue<>();
    /** A queue of blocks to be recovered by this datanode */
    private final BlockQueue<BlockInfo> recoverBlocks = new BlockQueue<>();
    /** A set of blocks to be invalidated by this datanode */
    private final LightWeightHashSet<Block> invalidateBlocks =
        new LightWeightHashSet<>();
    ...
}
```

We will analyse the memory consumption of `DatanodeDescriptor` in [Section 3.4 - Quantitative Analysis - Datanode Storage](https://dsl-umd.github.io/docs/analysis.html#datanode-storage).


## References

1. Heterogeneous Storage for HDFS: [https://issues.apache.org/jira/browse/HDFS-2832](https://issues.apache.org/jira/browse/HDFS-2832)

2. Subramanian Muralidhar, Wyatt Lloyd, Sabyasachi Roy, Cory Hill, Ernest Lin, Weiwen Liu, Satadru Pan, Shiva Shankar, Viswanath Sivakumar, Linpeng Tang, and Sanjeev Kumar. 2014. f4: Facebook's warm BLOB storage system. In Proceedings of the 11th USENIX conference on Operating Systems Design and Implementation (OSDI'14). USENIX Association, Berkeley, CA, USA, 383-398.

3. HDFS NameNode内存详解: [https://tech.meituan.com/2016/12/09/namenode-memory-detail.html](https://tech.meituan.com/2016/12/09/namenode-memory-detail.html)