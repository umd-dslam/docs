# Heterogeneous Storage

Each DataNode in a cluster is configured with a set of data directories. You can configure each data directory with a storage type.
The storage policy dictates which storage types to use when storing the file or directory. There are some reasons to consider using different types of storage: 

- You have datasets with temporal locality. The latest data can be loaded initially into SSD for improved performance, then migrated out to disk as it ages;
- You need to move cold data to denser archival storage because the data will rarely be accessed and archival storage is much cheaper. 

Many systems like Facebook's f4 used the same similar idea to provide low latency and sufficient throughput.

## DatanodeStorageInfo

## DatanodeDescriptor



## References

1. Heterogeneous Storage for HDFS: [https://issues.apache.org/jira/browse/HDFS-2832](https://issues.apache.org/jira/browse/HDFS-2832)

2. Subramanian Muralidhar, Wyatt Lloyd, Sabyasachi Roy, Cory Hill, Ernest Lin, Weiwen Liu, Satadru Pan, Shiva Shankar, Viswanath Sivakumar, Linpeng Tang, and Sanjeev Kumar. 2014. f4: Facebook's warm BLOB storage system. In Proceedings of the 11th USENIX conference on Operating Systems Design and Implementation (OSDI'14). USENIX Association, Berkeley, CA, USA, 383-398.