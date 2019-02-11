# Data Block

Hadoop HDFS stores terabytes and petabytes of data which far exceeds the size of a single disk as Hadoop framework break file into blocks and distribute across various nodes. By default, HDFS block size is 128MB which you can change as per your requirement. All HDFS blocks are the same size except the last block, which can be either the same size or smaller. Hadoop framework break files into 128 MB blocks and then stores into the Hadoop file system.  If HDFS Block size is 4kb like Linux file system, then we will have too many data blocks in Hadoop HDFS, hence too much of metadata. So, maintaining and managing this huge number of blocks and metadata will create huge overhead and traffic which is something which we don’t want. Block size can’t be so large that the system is waiting a very long time for one last unit of data processing to finish its work.

Namenode maintains the two most important relations in HDFS:

- Directory tree of HDFS file system and data block indexes of files (inodes **<-->** data block indexes);
- The mapping relationship between data blocks and datanodes, that is, the information on which datanodes a datablock is stored (data blocks **<-->** datanodes).

[INodeFile.blocks](https://github.com/DSL-UMD/hadoop-calvin/blob/calvin/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/INodeFile.java#L251) field records all data blocks a file contains. It is also through this field that HDFS associates the first relation with the second relation. INodeFile.blocks is an array of `BlockInfo` which inherits from `Block` class, HDFS uses `Block` to abstract the data structure in Namenode.

```java
public class INodeFile extends INodeWithAdditionalFields
    implements INodeFileAttributes, BlockCollection {
    private BlockInfo[] blocks;
    ...
}
```