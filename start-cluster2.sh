#!/bin/bash
# Copyright 2019, Cachengo, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#MASTER_IP is for you computer to connect via SSH.
#MASTER_HOSTNAME is where other servers in the cluster can reach it. (IPv6 not supported)
set -e
MASTER_IP=fd61:3542:8c18:137c:7999:9368:4c0e:5089
MASTER_HOSTNAME=192.168.1.27
NODE_MASTER_PORT=9000
REPLICATION=1
MAX_MEMORY=2500
MIN_MEMORY=612
DATANODE_DIR=/data/hadoop-data/datanode
NAMENODE_DIR=/data/hadoop-data//namenode
MAPRED_DIR=/data/mapred
HADOOP_TMP=/data/hadoop_tmp
VCORES=6
WORKER_IPS=(
    fd61:3542:8c18:137c:7999:9340:3194:3909
    fd61:3542:8c18:137c:7999:93de:a9cc:179e
    fd61:3542:8c18:137c:7999:93c5:c230:f66e
    fd61:3542:8c18:137c:7999:9375:c38f:f610   
    fd61:3542:8c18:137c:7999:932f:d373:b0c4
    fd61:3542:8c18:137c:7999:93e2:206c:a22e
    fd61:3542:8c18:137c:7999:9392:1f2a:8ff4
    fd61:3542:8c18:137c:7999:9368:4c0e:5089
 )


WORKER_HOSTNAMES=(
  192.168.1.107
  192.168.1.114
  192.168.1.110
  192.168.1.89
  192.168.1.193
  192.168.1.60
  192.168.1.220
  192.168.1.27
)


### No need to modify below this line

mkdir -p ./config
MAX_MEMORY_3=$((MAX_MEMORY / 3))
MAX_MEMORY_6=$((MAX_MEMORY / 6))


send_config () {
  HADOOP_HOME=$(ssh cachengo@$1 'echo $HADOOP_HOME')
  scp config/* cachengo@[$1]:$HADOOP_HOME/etc/hadoop/
}

ssh cachengo@$MASTER_IP 'stop-dfs.sh'
ssh cachengo@$MASTER_IP 'stop-yarn.sh'
ssh cachengo@$MASTER_IP 'mr-jobhistory-daemon.sh stop historyserver'
send_config $MASTER_IP
#ssh cachengo@$MASTER_IP "rm -rf $DATANODE_DIR"
#ssh cachengo@$MASTER_IP 'rm -rf $HADOOP_HOME/logs/*'
#ssh cachengo@$MASTER_IP 'bash -s' < ./ssh_config.sh
#ssh cachengo@$MASTER_IP 'bash -s' < ./master-init.sh

ssh cachengo@$MASTER_IP 'rm $HADOOP_HOME/etc/hadoop/slaves'

# Add the worker nodes
MASTER_PUB_KEY=`ssh cachengo@$MASTER_IP 'cat ~/.ssh/id_rsa.pub'`
for ((i=0;i<${#WORKER_IPS[@]};++i)); do

  echo "Sending config to ${WORKER_IPS[i]}"
  send_config "${WORKER_IPS[i]}"
  ssh cachengo@${WORKER_IPS[i]} "echo $MASTER_PUB_KEY >> "'~/.ssh/authorized_keys'
  ssh cachengo@${WORKER_IPS[i]} "sudo rm -rf $DATANODE_DIR"
  ssh cachengo@${WORKER_IPS[i]} 'rm -rf $HADOOP_HOME/logs/*'
  ssh cachengo@${WORKER_IPS[i]} "sudo mkdir -p $DATANODE_DIR"
  ssh cachengo@${WORKER_IPS[i]} "sudo chown -R cachengo:cachengo $DATANODE_DIR"
  ssh cachengo@${WORKER_IPS[i]} "sudo chmod -R a+rwx $DATANODE_DIR"
  ssh cachengo@${WORKER_IPS[i]} "sudo mkdir -p $HADOOP_TMP"
  ssh cachengo@${WORKER_IPS[i]} "sudo chown -R cachengo:cachengo $HADOOP_TMP"
  ssh cachengo@${WORKER_IPS[i]} "sudo chmod -R a+rwx $HADOOP_TMP"
  if [[ ${WORKER_IPS[i]} != $MASTER_IP  ]]
  then
    ssh cachengo@$MASTER_IP "echo ${WORKER_HOSTNAMES[i]} >> "'$HADOOP_HOME/etc/hadoop/slaves'
  fi
done

ssh cachengo@$MASTER_IP 'start-dfs.sh'
ssh cachengo@$MASTER_IP 'start-yarn.sh'
ssh cachengo@$MASTER_IP 'mr-jobhistory-daemon.sh start historyserver'
ssh cachengo@$MASTER_IP 'yarn namenode'

# Quick test
ssh cachengo@$MASTER_IP 'hdfs dfsadmin -report'
