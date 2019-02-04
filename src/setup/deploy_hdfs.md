# Deploy Hadoop HDFS in Container

After the compilation is complete, the next step is to consider how to deploy HDFS.
The deployment process is more complicated because it involves multiple components, such as multiple Datanodes, Namenode, and second Namenode. Here we start them through different processes on the same machine. How to deploy HDFS clusters will be introduced later.

1. add **linuxkit-025000000001** as an alias of localhost in `/etc/hosts`.

    ```bash
    # set password
    xxx@linuxkit-025000000001:~$ sudo passwd xxx  # user: xxx@linuxkit-025000000001
    xxx@linuxkit-025000000001:~$ sudo passwd root # user: root
    xxx@linuxkit-025000000001:~$ cat /etc/hostname

    linuxkit-025000000001

    xxx@linuxkit-025000000001:~$ cat /etc/hosts

    127.0.0.1       localhost
    ::1     localhost ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    ff00::0 ip6-mcastprefix
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters

    xxx@linuxkit-025000000001:~$ sudo vim /etc/hosts
    # add linuxkit-025000000001 into 127.0.0.1       localhost
    # 127.0.0.1       localhost linuxkit-025000000001

    xxx@linuxkit-025000000001:~$ cat /etc/hosts

    127.0.0.1       localhost linuxkit-025000000001
    ::1     localhost ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    ff00::0 ip6-mcastprefix
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters
    ```

2. create directories for various data generated by HDFS

    ```bash
    xxx@linuxkit-025000000001:~$ mkdir -p $HOME/hadoop/tmp
    xxx@linuxkit-025000000001:~$ mkdir -p $HOME/hadoop/name
    xxx@linuxkit-025000000001:~$ mkdir -p $HOME/hadoop/data
    ```

3. change both **core_site.xml** and **hdfs-site.xml** under `hadoop-dist/target/hadoop-3.3.0-SNAPSHOT/etc/hadoop/`

    - **core_site.xml**:

        ```xml
        <?xml version="1.0" encoding="UTF-8"?>
        <?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
        <configuration>
            <property>
                <name>fs.defaultFS</name>
                <value>hdfs://192.168.65.3:9000</value>
            </property>

            <property>
                <name>hadoop.tmp.dir</name>
                <value>/home/gangl/hadoop/tmp</value>
            </property>
        </configuration>
        ```

        Note: `/home/gangl` should be your `HOME` directory. `192.168.65.3` is retrieved by `/sbin/ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`.

    - **hdfs-site.xml**:

        ```xml
        <?xml version="1.0" encoding="UTF-8"?>
        <?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
        <configuration>
            <property>
                <name>dfs.replication</name>
                <value>1</value>
            </property>

            <property>
                <name>dfs.namenode.name.dir</name>
                <value>/home/gangl/hadoop/name</value>
            </property>

            <property>
                <name>dfs.datanode.data.dir</name>
                <value>/home/gangl/hadoop/data</value>
            </property>
            <property>
              <name>dfs.namenode.fs-limits.min-block-size</name>
              <value>10</value>
            </property>
            <property>
                <name>dfs.webhdfs.enabled</name>
                <value>true</value>
                <description>web permission to acccess HDFS</description>
            </property>
        </configuration>
        ```

        Note: `/home/gangl` should be your `HOME` directory.

4. generate a new SSH key

    ```bash
    xxx@linuxkit-025000000001:~$ sudo ssh-keygen -t rsa -f ~/.ssh/id_dsa  
    xxx@linuxkit-025000000001:~$ sudo cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys  
    xxx@linuxkit-025000000001:~$ sudo chmod 0600 ~/.ssh/authorized_keys
    xxx@linuxkit-025000000001:~$ sudo service ssh restart
    ```

5. set environment variables

    - set env variables in `hadoop-dist/target/hadoop-3.3.0-SNAPSHOT/etc/hadoop/hadoop-env.sh`:

        ```bash
        # 1. change env variables' value in hadoop-env.sh
        # note: `/home/gangl` should be your `HOME` directory.
        export HADOOP_ROOT_LOGGER=INFO,console
        export HADOOP_CLASSPATH="/home/gangl/java/postgresql-42.2.5.jar:"
        export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
        ```

    - set env variables in `/etc/environment`:

        ```bash
        # add JAVA_HOME to sudo vim /etc/environment
        xxx@linuxkit-025000000001:~$ sudo vim /etc/environment

        # add the following line into /etc/environment 
        JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-amd64"
        ```

6. deploy HDFS

    ```bash
    cd $HADOOP_HOME

    # reformat namenode
    xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ ./bin/hdfs namenode -format

    # kill former namenode and datanode processes
    xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ kill $(jps | grep '[NameNode,DataNode]' | awk '{print $1}')

    # deploy HDFS
    xxx@linuxkit-025000000001:~/.../hadoop-3.3.0-SNAPSHOT$ ./sbin/start-dfs.sh

    # check alive HDFS processes
    jps
    ```

    Note: using `jps` to make sure all three processes are running!