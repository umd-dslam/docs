# INode Metadata

Namenode stores metadata such as a file/directory's name, id, parent, children list, permission information and features, the number of blocks, number of replicas, a location of blocks, block IDs etc. This metadata is available in Namenode's memory for faster retrieval of data. The primary tasks of Namenode:

- Managing filesystem namespace and client's access to files;
- Executing file system operations such as naming, closing, opening files/directories;
- Receiving heartbeats and block reports from Datanode. It ensures that the Datanodes are alive. A block report contains a list of all blocks on a Datanode;
- Responsible for taking care of the Replication Factor of all the blocks (default value is 3).

**Under Construction**

