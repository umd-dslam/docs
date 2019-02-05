# HDFS Architecture

HDFS is a distributed file system from Hadoop designed for storing very large files running on a cluster of commodity hardware. It is designed on principle of storage of less number of large files rather than the huge number of small files. HDFS has 2 types of nodes that work in the cluster. They are Namenode(s) and Datanodes in master-slave fashion.

<img src="https://raw.githubusercontent.com/DSL-UMD/docs/master/src/img/hdfs-arch.png" class="center" style="width: 80%;" />

<span class="caption">Figure 2-1: System Architecture of Hadoop HDFS.</span>

## Namenode

Namenode allocates files access to the clients. It maintains and manages the directory tree, relations between blocks and files, Datanodes and assigns tasks to Datanodes. Namenode executes file system namespace operations like opening, closing, and renaming files and directories.


## Datanode

Datanodes manage storage of data. They serve read and write requests from the file system's clients. They also perform block creation, deletion, and replication upon instruction from the namenode. Once a block is written on a datanode, it replicates it to other datanode and process continues until the number of replicas mentioned is created.


## Persistence

HDFS metadata represents the structure of HDFS directories and files in a tree in memory of Namenode. Persistence of HDFS metadata broadly breaks down into 2 categories of files: `FSImage` in Namenode is an "Image file" which contains the entire filesystem namespace and is stored as a file in Namenode's local file system. It also contains a serialized form of all the directories and children inodes in the filesystem. Each inode is an internal representation of a file or directory's metadata; `EditLogs` contains all the recent modifications made to the file system on the most recent `FSImage`. Namenode receives a create/update/delete request from the client. After that this request is first recorded to edits file. Checkpointing is the process of merging the content of the most recent `FSImage` with all edits applied after that `FSImage` is merged in order to create a new `FSImage`. Checkpointing is triggered automatically by configuration policies or manually by HDFS administration commands.

