# Setting up Environment

In this section, you will learn how to setup the development environment. This project provides a flexible metadata storage layer to integrate different database systems into HDFS. For the sake of simplicity, only the Postgres integration is currently available. 

We have developed an isolation environment for development and experiment. All experiments are done in a docker container which is reproducible in any machines. Our containerized PostgreSQL exposes an external IP and Port for users, so that HDFS container can connect to PostgreSQL through JDBC Driver.
