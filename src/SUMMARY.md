# Summary


- [Proposal](./proposal.md)

---------------

- [Introduction](./intro/README.md)
    - [HDFS Architecture](./intro/hdfs.md)
    - [Deterministic Database](./intro/calvin.md)
    - [Horizontally Scale Namespace](./intro/new.md)

- [HDFS Metadata Management](./metadata/README.md)
    - [Namespace Management](./metadata/namespace/README.md)
        - [INode](./metadata/namespace/1.inode.md)
        - [File Operations](./metadata/namespace/2.fsop.md)
    - [Datablock Management](./metadata/datablock/README.md)
        - [Block and BlockInfo](./metadata/datablock/1.blockinfo.md)
    - [DataNode Management](./metadata/datenode/README.md)
        - [Heterogeneous Storage](./metadata/datanode/1.datanodeinfo.md)
    - [Data Model](./metadata/datamodel/README.md)
        - [Quantitative Analysis](./metadata/datamodel/1.analysis.md)
        - [Tables and CRUD Operations](./metadata/datamodel/2.crud.md)

- [Advanced Optimization](./opt/README.md)

- [Deterministic Database](./db/README.md)

---------------

- [Setting up Environment](./setup/README.md)
    - [Install Docker](./setup/install_docker.md)
    - [Build Postgres Image](./setup/postgres_image.md)
    - [Build Hadoop Dev Image](./setup/hadoop_image.md)
    - [Build Source Code](./setup/build_code.md)
    - [Deploy Hadoop HDFS](./setup/deploy_hdfs.md)
    - [HDFS Namenode Test](./setup/test.md)
    - [Rebuild Source Code](./setup/rebuild-optimization.md)


- [Benchmark](./benchmark.md)

---------------

- [Contributors](./misc/contributors.md)
