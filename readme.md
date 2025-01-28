# Document for this devops test

## Topics

- Run the test
- Provision Kubernetes Cluster
- Creating Helm Charts
- Create Single Executator File

### Run the test

First you must clone this repository with the command below and change directory to it:

```
git clone https://github.com/PooriaShahi/devops-test.git
cd devops-test
```

Then make sure you have **pip3** installed on your system. you can check that with the command below:

```
pip3 -V
```

If it's not installed on your system then do the below:
Python installation

```
python -m pip3 install --upgrade pip
```

Ubuntu installation

```
sudo apt install python3-pip
```

MacOS installation

```
brew install pip3
```

Then make sure that you have a server with **root user** and you have a **ssh-key based** authentication with it.

For your domain, please **change value of host in wart/values.yaml** file.

Then run the command below:

```
bash automate.sh
```

Enter you server's IP and _go make some snack and some coffee until magic completely happen_ ;)

When magic ends, you can see 2 different url based on your domain that defined in the **wart/values.yaml** file. Copy the urls and see the results.

### Provision Kubernetes Cluster

For this challenge i use [**kubespray**](https://kubespray.io) as recommended and provision a single node (CP+Worker) k8s cluster. I using **calico** CNI plugin for overlay k8s network. First creating my variables with the command below:

```
cd kubespray
cp -rfp ./kubespray/inventory/sample ./kubespray/inventory/mycluster
```

add inventory.ini add this configuration here

```
#[kube_control_plane]
#node1 ansible_host=nl-rv.maxtld.com ansible_port=3679 ansible_user=mohammad ip=10.254.11.134 etcd_member_name=etcd1

#[etcd:children]
#kube_control_plane

#[kube_node]
#node1

#[all:vars]
#ansible_ssh_user=mohammad
#ansible_become=true
#ansible_become_password='75@zBYbxIWcJzkM'

# This inventory file is for a single-node Kubernetes cluster with etcd running on the same node as the control plane

[all]
server1 ansible_host=nl-rv.maxtld.com ansible_port=3679 ansible_user=mohammad ip=10.254.11.134 etcd_member_name=etcd1

[kube_control_plane]
server1

[etcd]
server1

[kube_node]
server1

[k8s-cluster:children]
kube_control_plane
kube_node

[all:vars]
ansible_ssh_user=mohammad
ansible_become=true
k8s_version=v1.21.0
network_plugin=calico  # You can change the network plugin to another one if needed

```

after that add your ssh-key

```
ssh-copy-id -p 3679 root@nl-rv.maxtld.com
```

then when in kubespray dir just run:

```
ansible-playbook -i inventory/mycluster/inventory.ini  cluster.yml -b -v --private-key=~/.ssh/id_rsa -K -u mohammad
```

after a couple of mins your cluster is ready

**notice in ansible.cfg we set that all our command run with sudo**

**we get admin.conf for kubectl local-machine but for intraction we tunnel traffic between node and local-machine**

```
ssh -f -N -L 6443:10.254.11.134:6443 -p 3679 mohammad@nl-rv.maxtld.com
```

for using kubeconfig:

```
echo "export KUBECONFIG=/home/mohammad/.kube/admin.conf" >> ~/.bashrc
source ~/.bashrc
```

### Creating Helm Charts

for create helm chart

```
helm create wordpress-mysql-pma
```

after that add our configuration

In this chart for every objects, manifest written and we deploy the chart with the command below:

```
helm install wordpress-mysql-pma ./wordpress-mysql-pma
```

for down the deployment

```
helm uninstall wordpress-mysql-pma ./wordpress-mysql-pma
```

### Create Single Executator File

we have pre-install job for update and upgrade node **jobs/pre-install.ini**.
All this will be done with a **automate.sh** file which is a bash script file for implementing all together.
for destroy cluster use **destroy.sh**
