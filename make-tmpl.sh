#!/bin/bash
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
echo "Generating template files"
sed "s/{{NODE_MASTER}}/$MASTER_HOSTNAME/g" ./core-site.xml.tmpl > config/core-site.xml
sed -i'.original' "s/{{NODE_MASTER_PORT}}/$NODE_MASTER_PORT/g" config/core-site.xml
sed -i'.original' "s;{{HADOOP_TMP}};$HADOOP_TMP;g" config/core-site.xml

sed "s;{{HADOOP_HOME}};$HADOOP_HOME;g" ./hdfs-site.xml.tmpl > config/hdfs-site.xml
sed -i'.original' "s/{{REPLICATION}}/$REPLICATION/g" config/hdfs-site.xml
sed -i'.original' "s;{{DATANODE_DIR}};$DATANODE_DIR;g" config/hdfs-site.xml
sed -i'.original' "s;{{NAMENODE_DIR}};$NAMENODE_DIR;g" config/hdfs-site.xml


sed "s/{{MAX_MEMORY}}/$MAX_MEMORY/g" ./yarn-site.xml.tmpl > config/yarn-site.xml
sed -i'.original' "s/{{NODE_MASTER}}/$MASTER_HOSTNAME/g" config/yarn-site.xml
sed -i'.original' "s/{{NODE_MASTER}}/$MASTER_HOSTNAME/g" config/hdfs-site.xml
sed -i'.original' "s/{{VCORES}}/$VCORES/g" config/yarn-site.xml

sed "s;{{MAPRED_DIR}};$MAPRED_DIR;g" ./mapred-site.xml.tmpl > config/mapred-site.xml
sed -i'.original' "s/{{MAX_MEMORY}}/$MAX_MEMORY/g" config/mapred-site.xml
sed -i'.original' "s/{{MAX_MEMORY}}/$MAX_MEMORY/g" config/yarn-site.xml
sed -i'.original' "s/{{VCORES}}/$VCORES/g" config/mapred-site.xml

sed "s/{{MAX_MEMORY}}/$MAX_MEMORY/g" ./capacity-scheduler.xml.tmpl > config/capacity-scheduler.xml
sed "s/{{MAX_MEMORY}}/$MAX_MEMORY/g" ./resource-types.xml.tmpl > config/resource-types.xml
