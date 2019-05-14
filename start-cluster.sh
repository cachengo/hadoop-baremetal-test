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
MASTER_IP=fd25:2573:93b1:a1ef:be99:9347:7a11:e745
MASTER_HOSTNAME=node-master
NODE_MASTER_PORT=9000
REPLICATION=1
MAX_MEMORY=3072
DATANODE_DIR=/data/datanode
NAMENODE_DIR=/data/namenode
MAPRED_DIR=/data/mapred
HADOOP_TMP=/data/hadoop_tmp
VCORES=6
WORKER_IPS=(
  fd25:2573:93b1:a1ef:be99:9393:2cd0:e84a
  fd25:2573:93b1:a1ef:be99:939f:8923:13fe
  fd25:2573:93b1:a1ef:be99:9374:53a2:8caa
  fd25:2573:93b1:a1ef:be99:93fe:8e17:57d4
  fd25:2573:93b1:a1ef:be99:9382:c5cd:15f
  fd25:2573:93b1:a1ef:be99:93d7:5e7b:a5f5
  fd25:2573:93b1:a1ef:be99:9346:a1a7:870f
)
WORKER_HOSTNAMES=(
  192.168.86.62
  192.168.86.40
  192.168.86.49
  192.168.86.54
  192.168.86.55
  192.168.86.58
  192.168.86.60
)


### No need to modify below this line

mkdir -p ./config
MAX_MEMORY_3=$((MAX_MEMORY / 3))
MAX_MEMORY_6=$((MAX_MEMORY / 6))

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
sed -i "s/{{VCORES}}/$VCORES/g" config/mapred-site.xml


send_config () {
  HADOOP_HOME=$(ssh root@$1 'echo $HADOOP_HOME')
  scp config/* root@[$1]:$HADOOP_HOME/etc/hadoop/
}

ssh root@$MASTER_IP 'stop-dfs.sh'
ssh root@$MASTER_IP 'stop-yarn.sh'
ssh root@$MASTER_IP 'mr-jobhistory-daemon.sh stop historyserver'
send_config $MASTER_IP
ssh root@$MASTER_IP "rm -rf $DATANODE_DIR"
ssh root@$MASTER_IP 'rm -rf $HADOOP_HOME/logs/*'
ssh root@$MASTER_IP 'bash -s' < ./ssh_config.sh
ssh root@$MASTER_IP 'bash -s' < ./master-init.sh

ssh root@$MASTER_IP 'rm $HADOOP_HOME/etc/hadoop/slaves'

# Add the worker nodes
MASTER_PUB_KEY=`ssh root@$MASTER_IP 'cat ~/.ssh/id_rsa.pub'`
for ((i=0;i<${#WORKER_IPS[@]};++i)); do

  send_config "${WORKER_IPS[i]}"
  ssh root@${WORKER_IPS[i]} "echo $MASTER_PUB_KEY >> "'~/.ssh/authorized_keys'
  ssh root@${WORKER_IPS[i]} "rm -rf $DATANODE_DIR"
  ssh root@${WORKER_IPS[i]} 'rm -rf $HADOOP_HOME/logs/*'
  ssh root@$MASTER_IP "echo ${WORKER_HOSTNAMES[i]} >> "'$HADOOP_HOME/etc/hadoop/slaves'
done

ssh root@$MASTER_IP 'start-dfs.sh'
ssh root@$MASTER_IP 'start-yarn.sh'
ssh root@$MASTER_IP 'mr-jobhistory-daemon.sh start historyserver'

# Quick test
ssh root@$MASTER_IP 'hdfs dfsadmin -report'
