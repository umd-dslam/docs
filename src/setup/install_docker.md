
# Install Docker

Due to the complexity of this project, Hadoop compilation involves a lot of dependencies. It is very hard to reproduce the experimental results on bare metal. The best way to solve this problem for anyone is to use the Docker.

[Docker](https://en.wikipedia.org/wiki/Docker_(software)) is a computer program that performs operating-system-level virtualization. Docker is used to run software packages called "containers". Containers are isolated from each other and bundle their own application, tools, libraries and configuration files; they can communicate with each other through well-defined channels. All containers are run by a single operating-system kernel and are thus more lightweight than virtual machines. Containers are created from "images" that specify their precise contents. Images are often created by combining and modifying standard images downloaded from public repositories.

You can download and install Docker from this webpage: [https://docs.docker.com/install/](https://docs.docker.com/install/). Docker
is available on multiple platforms. For example, Desktop (Mac and Windows), Server (CentOS, Debian, Fedora and Ubuntu).


After installation, you can issue the command to verify its version:

```bash
$ docker --version

Docker version 18.05.0-ce, build f150324
```
