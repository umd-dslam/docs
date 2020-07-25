# Setting up Environment

In this section, you will learn how to setup the development environment. FileScale provides a flexible database layer to conveniently integrate different database systems into HDFS. We developed an isolation environment for continuous development. To make FileScale reproducible in anytime and anywhere, all experiments are evaluated in the docker containers or AWS EC2 instances. Our containerized database system exposes an external IP and Port for users, so that HDFS can connect to it through the JDBC-compliant driver.

Currently, FileScale supports PostgreSQL, CockroachDB and VoltDB. For the sake of simplicity and completeness, we recommend you choose VoltDB as FileScale's underlying database system. 
