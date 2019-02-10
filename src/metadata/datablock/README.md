# Datablock Management

Hadoop HDFS split large files into small chunks known as Blocks. Block is the physical representation of data. It contains a minimum amount of data that can be read or write. HDFS stores each file as blocks. HDFS client doesn’t have any control on the block like block location, Namenode decides all such things. We introduced that all inodes and data block indexes in HDFS Namespace will be serialized into FSImage file and persisted on Namenode's hard drive eventually (See [Section 2.1](https://dsl-umd.github.io/docs/intro/hdfs.html#persistence)). 


However, the relation between data blocks and Datanode haven't been stored in FSImage. In contrast, it's dynamically constructed from the heartbelt of Datanode. No matter where the relations of `INode <-> data block indexes` and `data block <-> Datanode` were before, they can be stored through the database.

## Data Block

Hadoop HDFS stores terabytes and petabytes of data which far exceeds the size of a single disk as Hadoop framework break file into blocks and distribute across various nodes. By default, HDFS block size is 128MB which you can change as per your requirement. All HDFS blocks are the same size except the last block, which can be either the same size or smaller. Hadoop framework break files into 128 MB blocks and then stores into the Hadoop file system.  If HDFS Block size is 4kb like Linux file system, then we will have too many data blocks in Hadoop HDFS, hence too much of metadata. So, maintaining and managing this huge number of blocks and metadata will create huge overhead and traffic which is something which we don’t want. Block size can’t be so large that the system is waiting a very long time for one last unit of data processing to finish its work.

