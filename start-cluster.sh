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
MASTER_IP=fd25:2573:93b1:a1ef:be99:93c6:e85f:6958
MASTER_HOSTNAME=b2-n1
MASTER_LOCAL_IP=192.168.86.206
NODE_MASTER_PORT=9000
REPLICATION=1
MAX_MEMORY=3072
DATANODE_DIR=/data/datanode
NAMENODE_DIR=/data/namenode
MAPRED_DIR=/data/mapred
HADOOP_TMP=/data/hadoop_tmp
VCORES=6
WORKER_IPS=(
  fd25:2573:93b1:a1ef:be99:9370:852d:6af9
  fd25:2573:93b1:a1ef:be99:9332:d9d4:3b58
  fd25:2573:93b1:a1ef:be99:9395:ea74:1ce8
  fd25:2573:93b1:a1ef:be99:9375:8700:714c
  fd25:2573:93b1:a1ef:be99:9311:459b:a403
  #fd25:2573:93b1:a1ef:be99:9394:90db:254e
  #fd25:2573:93b1:a1ef:be99:9344:2eb0:a6cc
)
WORKER_LOCAL_IPS=(
  192.168.86.204
  192.168.86.207
  192.168.86.203
  192.168.86.205
  192.168.86.190
  #192.168.86.194
  #192.168.86.195
)
WORKER_HOSTNAMES=(
  b2-n2
  b2-n3
  b2-n4
  b2-n5
  b2-n6
  #b2-n7
  #b2-n8
)

USER=ash


### No need to modify below this line

mkdir -p ./config
MAX_MEMORY_4=$((MAX_MEMORY / 4))
MAX_MEMORY_8=$((MAX_MEMORY / 8))

echo "====== Preparing Templates ======"
sed "s/{{NODE_MASTER}}/$MASTER_HOSTNAME/g" ./core-site.xml.tmpl > config/core-site.xml
sed -i "s/{{NODE_MASTER_PORT}}/$NODE_MASTER_PORT/g" config/core-site.xml
sed -i "s;{{HADOOP_TMP}};$HADOOP_TMP;g" config/core-site.xml

sed "s;{{HADOOP_HOME}};$HADOOP_HOME;g" ./hdfs-site.xml.tmpl > config/hdfs-site.xml
sed -i "s/{{REPLICATION}}/$REPLICATION/g" config/hdfs-site.xml
sed -i "s;{{DATANODE_DIR}};$DATANODE_DIR;g" config/hdfs-site.xml
sed -i "s;{{NAMENODE_DIR}};$NAMENODE_DIR;g" config/hdfs-site.xml


sed "s/{{MAX_MEMORY}}/$MAX_MEMORY/g" ./yarn-site.xml.tmpl > config/yarn-site.xml
sed -i "s/{{NODE_MASTER}}/$MASTER_HOSTNAME/g" config/yarn-site.xml
sed -i "s/{{VCORES}}/$VCORES/g" config/yarn-site.xml

sed "s;{{MAPRED_DIR}};$MAPRED_DIR;g" ./mapred-site.xml.tmpl > config/mapred-site.xml
sed -i "s/{{MAX_MEMORY}}/$MAX_MEMORY/g" config/mapred-site.xml
sed -i "s/{{MAX_MEMORY_8}}/$MAX_MEMORY_8/g" config/mapred-site.xml
sed -i "s/{{MAX_MEMORY_4}}/$MAX_MEMORY_4/g" config/mapred-site.xml
sed -i "s/{{VCORES}}/$VCORES/g" config/mapred-site.xml

echo "$MASTER_LOCAL_IP $MASTER_HOSTNAME" > config/hadoop_hosts
for ((i=0;i<${#WORKER_IPS[@]};++i)); do
  echo "${WORKER_LOCAL_IPS[i]} ${WORKER_HOSTNAMES[i]}" >> config/hadoop_hosts
done


send_config () {
  HADOOP_HOME=$(ssh $USER@$1 'echo $HADOOP_HOME')
  scp config/* $USER@[$1]:$HADOOP_HOME/etc/hadoop/
}

echo "====== Setting up Master ======"
ssh $USER@$MASTER_IP 'bash -s' < ./ssh_config.sh
MASTER_PUB_KEY=`ssh $USER@$MASTER_IP 'cat ~/.ssh/id_rsa.pub'`
ssh $USER@$MASTER_IP "echo $MASTER_PUB_KEY >> "'~/.ssh/authorized_keys'
ssh $USER@$MASTER_IP 'stop-dfs.sh'
ssh $USER@$MASTER_IP 'stop-yarn.sh'
ssh $USER@$MASTER_IP 'mr-jobhistory-daemon.sh stop historyserver'
send_config $MASTER_IP
ssh $USER@$MASTER_IP "sed -i '/127.0.1.1/d' /etc/hosts"
ssh $USER@$MASTER_IP \
  'while read -r line; do grep -qxF "$line" /etc/hosts || echo $line | sudo tee -a /etc/hosts; done' \
   < config/hadoop_hosts
ssh $USER@$MASTER_IP "rm -rf $DATANODE_DIR"
ssh $USER@$MASTER_IP 'rm -rf $HADOOP_HOME/logs/*'
ssh $USER@$MASTER_IP 'bash -s' < ./master-init.sh

ssh $USER@$MASTER_IP 'rm $HADOOP_HOME/etc/hadoop/slaves'

# Add the worker nodes
echo "====== Setting up Workers ======"
for ((i=0;i<${#WORKER_IPS[@]};++i)); do
  send_config "${WORKER_IPS[i]}"
  ssh $USER@${WORKER_IPS[i]} "sudo sed -i '/127.0.1.1/d' /etc/hosts"
  ssh $USER@${WORKER_IPS[i]}  \
    'while read -r line; do grep -qxF "$line" /etc/hosts || echo $line | sudo tee -a /etc/hosts; done' \
     < config/hadoop_hosts
  ssh $USER@${WORKER_IPS[i]} "echo $MASTER_PUB_KEY >> "'~/.ssh/authorized_keys'
  ssh $USER@${WORKER_IPS[i]} "rm -rf $DATANODE_DIR"
  ssh $USER@${WORKER_IPS[i]} 'rm -rf $HADOOP_HOME/logs/*'
  ssh $USER@$MASTER_IP "echo ${WORKER_HOSTNAMES[i]} >> "'$HADOOP_HOME/etc/hadoop/slaves'
done

ssh $USER@$MASTER_IP 'start-dfs.sh'
ssh $USER@$MASTER_IP 'start-yarn.sh'
ssh $USER@$MASTER_IP 'mr-jobhistory-daemon.sh start historyserver'

# Quick test
ssh $USER@$MASTER_IP 'hdfs dfsadmin -report'
