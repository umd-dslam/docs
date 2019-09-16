
```bash
# https://tecadmin.net/install-ruby-latest-stable-centos/
# install ruby

gem install berkshelf


wget https://packages.chef.io/files/stable/chefdk/2.0.28/el/7/chefdk-2.0.28-1.el7.x86_64.rpm
sudo rpm -ivh chefdk-2.0.28-1.el7.x86_64.rpm


sudo yum -y install gcc make patch dkms qt libgomp epel-release
# Install VirtualBox
cd /etc/yum.repos.d
sudo wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo
sudo yum install VirtualBox-5.1
export KERN_DIR=/usr/src/kernels/$(uname -r)
sudo /sbin/rcvboxdrv setup
sudo yum -y install https://releases.hashicorp.com/vagrant/1.9.7/vagrant_1.9.7_x86_64.rpm


wget https://hopsworks.readthedocs.io/en/latest/_downloads/e150a261128e5d4a0c804611e116503c/simplesetup.sh
# change line 33 to ./run.sh ubuntu 1 hops 

sudo bash ./simplesetup.sh --install-deps

sudo vagrant plugin install vagrant-disksize


config.vm.provider :virtualbox do |v|
  v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  v.customize ["modifyvm", :id, "--memory", 31966]
  v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  v.customize ["modifyvm", :id, "--nictype1", "virtio"]
  v.customize ["modifyvm", :id, "--name", "hopsworks0"]
  v.customize ["modifyvm", :id, "--cpus", "8"]
  v.customize ["modifyvm", :id, "--ioapic", "on"]
end


sudo vagrant up
sudo vagrant ssh
```

```bash
cd /srv/hops/hadoop-2.8.2.8
vim etc/hadoop/hadoop-env.sh
export HADOOP_ROOT_LOGGER=INFO,console


jps
27249 Jps
20088 NameNode
24633 ResourceManager
22202 DataNode
26797 NodeManager

kill 20088 24633 22202 26797
```

```bash
./sbin/start-nn.sh
./bin/hdfs namenode -format
hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark  -op create -threads 1 -files 10000 -filesPerDir 10000 -keepResults -logLevel INFO
```
