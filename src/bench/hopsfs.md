
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
sudo vagrant up
sudo vagrant ssh
```
