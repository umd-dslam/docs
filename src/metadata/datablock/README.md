# Datablock Management

Hadoop HDFS split large files into small chunks known as Blocks. Block is the physical representation of data. It contains a minimum amount of data that can be read or write. HDFS stores each file as blocks. HDFS client doesn’t have any control on the block like block location, Namenode decides all such things. We introduced that all inodes and data block indexes in HDFS Namespace will be serialized into FSImage file and persisted on Namenode's hard drive eventually (See [Section 2.1](https://dsl-umd.github.io/docs/intro/hdfs.html#persistence)). 


However, the relation between data blocks and Datanode haven't been stored in FSImage. In contrast, it's dynamically constructed from the heartbelt of Datanode. No matter where the relations of `INode <-> data block indexes` and `data block <-> Datanode` were before, they can be stored through the database.

## Data Block

