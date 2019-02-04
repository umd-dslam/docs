# HDFS Metadata Management

Namenode stores metadata such as file and directory names, IDs, parents, children lists, permission information and features, # of blocks, block attributes, etc in memory for faster retrieval of data. The primary tasks of Namenode:

- Managing file system namespace and client’s access to files;
- Executing file system operations such as naming, closing, opening files/directories;
- Receiving heartbeats and block reports from Datanode. It ensures that the Datanodes are alive. A block report contains a list of all blocks on a Datanode;
- Responsible for taking care of the Replication Factor of all the blocks (default value is 3).

This section is divided into two main parts. The first part is how to replace file system namespace from Namenode's memory to database systems. The second part is how to put the mapping among files, data blocks and dataNodes from Namenode to database systems.
