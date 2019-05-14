# hadoop-baremetal-test
Code and instructions for setting up a simple hadoop cluster

**NOTE:** The scripts in this repository are very raw and not very stable. They are mostly meant to give you an idea on how to get things going but with a bit of modification they might work on your system.

## Step 1: Install Hadoop on every node
`ssh me@nodeX 'bash -s' < ./install.sh`
This only needs to be done once

## Step 2: Start the cluster
1. Modify parameters at the top of start-cluster.sh
2. Run ./start-cluster.sh from a computer with ssh access to the required nodes
3. Go to: http://<MASTER_IP>:8088/cluster/nodes and make sure everything looks good

## Step 3: Run TestDFSIO
```
hadoop jar \
  $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.8.5-tests.jar \
  TestDFSIO \
  -write \
  -nrFiles 5 \
  -fileSize 20GB \
-resFile /tmp/TestDFSIOwrite.txt
```

## Step 4: Clean Up
```
hadoop jar \
  $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.8.5-tests.jar \
  TestDFSIO \
  -clean
```
