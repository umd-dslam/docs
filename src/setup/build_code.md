
# Build Custom Source Code in Container

Since the local directory is mounted to the internal directory of the container by default [start-build-env.sh#L88](https://github.com/DSL-UMD/hadoop-calvin/blob/c337680e23ded375df17c09a878f719102a47773/start-build-env.sh#L88), you can build Hadoop souce code in **hadoop-dev** container.


```bash
# Build Hadoop in hadoop-dev container
xxx@linuxkit-025000000001:~$ USER=$(ls /home/)
xxx@linuxkit-025000000001:~$ chown -R $USER /home/$USER/.m2

# Compile HDFS
xxx@linuxkit-025000000001$ mvn clean package -Pdist -Pnative -Dtar -DskipTests
```

