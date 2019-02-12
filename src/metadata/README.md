# HDFS Metadata Management

Namenode stores the metadata of filesystem namespaces and data blocks in memory for faster retrieval of data. The primary tasks of the Namenode:

- Managing filesystem namespace and client’s access to files;
- Executing filesystem operations such as naming, closing, opening files/directories;
- Receiving heartbeats and block reports from Datanode. It ensures that the Datanodes are alive. A block report contains a list of all blocks on a Datanode;
- Responsible for taking care of the Replication Factor of all the blocks (default value is 3).

This section is divided into four main parts. The first part focuses on how HDFS represents inodes and maintains a directory tree. 
The second part is to explain the relations of `files - data blocks` and `data block - datanodes` in the Namenode.
The third part is how HDFS maintains a network topology of the entire cluster. 
In the final part, we quantify the memory consumption of various data structures in the Namenode and 
propose a new data model to store metadata in the database.
