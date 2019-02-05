# Research Proposal

Hadoop HDFS is an extremely widely used parallel processing platform around the world. During the past 10 years, HDFS has been used by many organizations since the need for large distributed storage systems backed by distributed computational frameworks like [Tensorflow](https://tensorflow.org), MapReduce and [Spark](https://spark.apache.org) is eager and urgent. 

However, HDFS is originally designed to be built upon the single-node namespace server architecture. Since the Namenode is a single container of the file system metadata, it has known scalability bottlenecks when there are lots of small files stored on one spot. In order to make metadata operations fast, the Namenode loads the whole namespace including the directory tree and all meta-data of files into its memory, and therefore the size of the namespace is limited by the amount of
RAM available.

There are a few distributed file systems that distribute the namespace server itself both for workload balancing and for reducing the single server memory footprint. [Ceph](https://ceph.com/) has a cluster of namespace servers (MDS) and uses a dynamic subtree partitioning algorithm in order to map the namespace tree to MDSes evenly. Google also announced that [GFS](https://queue.acm.org/detail.cfm?id=1594206) has evolved into a distributed namespace server system. The new GFS can have hundreds of namespace servers (Namenodes) with 100 million files per master.

To unlock the scalability of HDFS, we propose that the file system metadata and the directory tree structure in HDFS Namenode can be removed from memory and stored into a [deterministic database](http://www.cs.umd.edu/~abadi/papers/abadi-cacm2018.pdf). Metadata can be partitioned and replicated across a shared-nothing cluster of independent servers, and operations on file metadata transformed into distributed transactions.

The difference between this project and above solutions is that it is a deterministic database. uses a deterministic ordering guarantee to significantly reduce the normally prohibitive contention costs associated with distributed transactions which can support disk-based storage scales near-linearly on a cluster of commodity machines and has no singlepoint of failure. which has
shown to be a promising direction to improving transactional database system scalability, modularity, throughput, and replication.

The source code is currently hosted on github: [https://github.com/DSL-UMD](https://github.com/DSL-UMD).

This proposal is still **in progress**!


