# HDFS Metadata Management

Namenode stores the metadata of filesystem namespaces and data blocks in memory for faster retrieval of data. The primary tasks of Namenode:

- Managing filesystem namespace and client’s access to files;
- Executing filesystem operations such as naming, closing, opening files/directories;
- Receiving heartbeats and block reports from Datanode. It ensures that the Datanodes are alive. A block report contains a list of all blocks on a Datanode;
- Responsible for taking care of the Replication Factor of all the blocks (default value is 3).

This section is divided into two main parts. The first part is how to replace file system namespace from Namenode's memory to database systems. The second part is how to put the mapping among files, data blocks and Datanodes from Namenode to database systems.
