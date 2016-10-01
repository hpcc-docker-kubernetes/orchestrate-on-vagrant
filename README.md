# Setup a simple HPCCSystems Cluster on Kubernetes/Vagrant/Virtualbox

## Introduction
Due to lack of general support for persistent volume on current Kubernetes we only show 
a normal HPCCSystems cluster setup. It will include a dali/support node and initial one
roxie and one thor node. User can scale roxie and thor nodes. Originally there will be
one master and three minions (VMs). You need to have more minions if plan to scale more
roxie or thor nodes.


Keep in mind since no shared volume any ip change will require re-generating environment.xml. 
Roxie and Thor data will be re-processed.
For environment.xml and stop/start the cluster there is mon_ips.sh running in hpcc-ansible node.
If enabled it should take care of this.

Access esp node may still be little inconvenient. We will use minions (VMs) ips to access 
ECLWatch for now.


## Rerequisites

1. VirtualBox
2. Vagrant
3. Kubernetes


## Setup Kubernetes with Vagrant/Virtualbox
Get orchestrate-on-vagrant from github:
```sh
git clone https://github.com/hpcc-docker-kubernetes/orchestrate-on-vagrant

```
Update PATH variable based on your Kubernetes installed directory and OS type

Source orchestrate-on-vagrant/env
and go to Kubernetes home directory and run
```sh
cluster/kube-up.sh
```
This will take a while. It will create a master VM and several minions VMs depends on NUM_NODES
defined in env file. It will deploy several kubernetes docker containers.

When finish run following to view kubernetes services:
```sh
kubectl cluster-info
Kubernetes master is running at https://10.245.1.2
Heapster is running at https://10.245.1.2/api/v1/proxy/namespaces/kube-system/services/heapster
KubeDNS is running at https://10.245.1.2/api/v1/proxy/namespaces/kube-system/services/kube-dns
kubernetes-dashboard is running at https://10.245.1.2/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard
Grafana is running at https://10.245.1.2/api/v1/proxy/namespaces/kube-system/services/monitoring-grafana
InfluxDB is running at https://10.245.1.2/api/v1/proxy/namespaces/kube-system/services/monitoring-influxdb

```


## Deploy HPCCSystems cluster
go github orchestrate-on-vagrant/bin and run
```sh
./create-all.sh
replicationcontroller "roxie-rc" created
replicationcontroller "thor-rc" created
replicationcontroller "dali-rc" created
pod "hpcc-ansible" created
```

Check deployed pods:
```sh
kubectl get pods
NAME             READY     STATUS              RESTARTS   AGE
dali-rc-xxk0s    1/1       Running             0          1m
hpcc-ansible     0/1       ContainerCreating   0          1m
roxie-rc-iw0h1   1/1       Running             0          1m
thor-rc-dmeod    1/1       Running             0          1m
```
Wait for all pods are in "Running" status.

## Configure HPCCSystems cluster
Access the hpcc-ansible pod
```sh
kubectl exec -it hpcc-ansible -- bash -il

```

Configure HPCCSystems cluster
```sh
cd /opt/hpcc-tools
./config_hpcc.sh

...

/opt/HPCCSystems/sbin/envgen -env /etc/HPCCSystems/environment.xml  
   -override roxie,@copyResources,true   
   -override roxie,@roxieMulticastEnabled,false  
   -override thor,@replicateOutputs,true  
   -override esp,@method,htpasswd  
   -override thor,@replicateAsync,true        
   -thornodes 1 -slavesPerNode 1 -espnodes 0 -roxienodes 1 
   -supportnodes 1 -roxieondemand 1 -ip 10.246.88.4 
   -assign_ips thor 10.246.88.4\;10.246.88.3\; 
   -assign_ips roxie 10.246.88.2\;

...

/opt/HPCCSystems/sbin/configgen -env /etc/HPCCSystems/environment.xml -listall2
EclAgentProcess,myeclagent,10.246.88.4,,/var/lib/HPCCSystems/myeclagent,
FTSlaveProcess,myftslave,10.246.88.4,,/var/lib/HPCCSystems/myftslave,
FTSlaveProcess,myftslave,10.246.88.3,,/var/lib/HPCCSystems/myftslave,
FTSlaveProcess,myftslave,10.246.88.2,,/var/lib/HPCCSystems/myftslave,
SashaServerProcess,mysasha,10.246.88.4,8877,/var/lib/HPCCSystems/mysasha,.
RoxieServerProcess,myroxie,10.246.88.2,,/var/lib/HPCCSystems/myroxie,
DaliServerProcess,mydali,10.246.88.4,7070,/var/lib/HPCCSystems/mydali,
DfuServerProcess,mydfuserver,10.246.88.4,,/var/lib/HPCCSystems/mydfuserver,
EclCCServerProcess,myeclccserver,10.246.88.4,,/var/lib/HPCCSystems/myeclccserver,
EspProcess,myesp,10.246.88.4,,/var/lib/HPCCSystems/myesp,
DafilesrvProcess,mydafilesrv,10.246.88.4,,/var/lib/HPCCSystems/mydafilesrv,
DafilesrvProcess,mydafilesrv,10.246.88.3,,/var/lib/HPCCSystems/mydafilesrv,
DafilesrvProcess,mydafilesrv,10.246.88.2,,/var/lib/HPCCSystems/mydafilesrv,
ThorMasterProcess,mythor,10.246.88.4,20000,/var/lib/HPCCSystems/mythor,
ThorSlaveProcess,mythor,10.246.88.3,,/var/lib/HPCCSystems/mythor,
EclSchedulerProcess,myeclscheduler,10.246.88.4,,/var/lib/HPCCSystems/myeclscheduler,
HPCC cluster configuration is done.

```

enable mon_ips.sh script to monitor the ip change:
```sh
./enable
```
The log will be in /var/log/hpcc-tools/mon_ips.log 


## Expose ESP through Kubernetes service 
esp component is included in dali pod which have a private ip not accessible from host system directly.
We provide a esp-service.yaml but the externalIPs should be changed to your minions ips.
To get your minions ips:
```sh
                "addresses": [
                        "address": "10.245.1.3"
                        "address": "10.245.1.3"
                "addresses": [
                        "address": "10.245.1.4"
                        "address": "10.245.1.4"
                "addresses": [
                        "address": "10.245.1.5"
                        "address": "10.245.1.5"
```
Replace the ips list of externalIPs field with these values. You only need one ip but list more doesn't hurt.
Create esp service:
```sh
kubectl create -f esp-service.yaml
```
Display the service
```sh
kubectl get service
NAME         CLUSTER-IP      EXTERNAL-IP             PORT(S)             AGE
esp          10.247.197.90   10.245.1.3,10.245.1.4   8010/TCP,8002/TCP   8h
kubernetes   10.247.0.1      <none>                  443/TCP             8d
```
Use one of the EXTERNAL-IP to access ECLWatch
For example http://10.245.1.3:8010
The ports exposed are 8010 and 8002. You can open more ports in esp-service.yaml
You need stop/start the service :

## Use/Scale the cluster
The above ip can be used ECL IDE. 
You can increate or descrease roxie and thor node numbers.
For example to scale up thor to 2: 
```sh
kubectl scale rc thor-rc --replicas=2

kubectl get pods
NAME             READY     STATUS    RESTARTS   AGE
dali-rc-xxk0s    1/1       Running   0          5h
hpcc-ansible     1/1       Running   0          5h
roxie-rc-iw0h1   1/1       Running   0          5h
thor-rc-dmeod    1/1       Running   0          5h
thor-rc-lmaz5    1/1       Running   0          8s
```
Remember ths will cause a new environment.xml be generated and the cluster stop/start


## Destroy HPCCSystems cluster
```sh
./bin/destroy-all.sh
```

## Teardown Kubernetes 
Under Kubernetes home:
```sh
cluster/kube-down.sh
```
./bin/destroy-all.sh
