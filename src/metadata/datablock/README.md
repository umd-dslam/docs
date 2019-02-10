# Datablock Management

We introduced that all `INode` and data block indexes in HDFS Namespace will be serialized into `FSImage` file and persisted on Namenode's hard drive eventually (See [Section 2.1](https://dsl-umd.github.io/docs/intro/hdfs.html#persistence)). However, the relation between data blocks and Datanode haven't been stored in `FSImage`. In contrast, it's dynamically constructed from the heartbelt of Datanode.

