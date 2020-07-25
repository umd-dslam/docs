
# Build FileScale

Since the local directory is mounted into the container by default, you can build FileScale using the container.


```shell
# Build Hadoop in hadoop-dev container
xxx@linuxkit-025000000001:~$ USER=$(ls /home/)
xxx@linuxkit-025000000001:~$ chown -R $USER /home/$USER/.m2

# Compile HDFS
xxx@linuxkit-025000000001$ mvn clean package -Pdist -Pnative -Dtar -DskipTests
```

