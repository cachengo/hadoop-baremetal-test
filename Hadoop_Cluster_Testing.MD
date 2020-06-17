# Hadoop Cluster Testing for Cachengo Inc.

## Purpose

  The purpose of this document is to document Hadoop Tests done on Cachengo's 8 server Linux cluster, explain how to set up Hadoop on said cluster and also to explain some of the utility scripts included in this branch of the repository.


## Getting Started

The first step is to install Hadoop in all 8 servers in the cluster. This can be a little time consuming, but a utility script called **install-hadoop-all.sh** is provided to help with this process. This script executes the **install.sh** script in all the servers in the cluster. Before running **install-hadoop-all.sh** make sure to set up the IPv6 Addrresses of each server in the hosts array. Also make sure the machine running the script has ssh access to each server. Setting up ssh access is beyond the scope of this document. 

**install-hadoop-all.sh** will output a "Running install script on [server ip]" message before running **install.sh** on each server. Should any installation fail, look for the final instance of this message to see which server failed to install.  Before attempting to reinstall on that server, the folders **/hadoop** and **~/hadoop** must be deleted, otherwise, **install.sh** will assume that installation was successful and not run on that server.

The Hadoop version install by these scripts is 2.10.0, but can be changed on **install.sh** by modifying the value of the VERSION variable. 

Execute **install-hadoop-all.sh** by typing 

`./install-hadoop-all.sh`

on your terminal.

## Starting the cluster

Use the **start-cluster.sh** script to actually start the Hadoop cluster. It may be necessary to update the IP Addrresses included here.  You can also adjust a few settings that will be copied onto Hadoop's XML configuration files. Adjust these to tweak performance.

## Running tests

Scripts are provided to run popular Hadoop benchmarking tools, described below:

1. **run_dfsio_write.sh** - Runs TestDFSIO write test
2. **run_dfsio.sh** - Runs TestDFSIO read test (Note: you MUST run the write test first).
3. **run_teragen.sh**, **run_terasort.sh** and **run_terval.sh** - Runs the popular TeraGen, TeraSort and Tera Validate benchmarks.  They must be run in that specific order.

## Automated test script

The **run_auto.py** script will run TestDFSIO write test using different low/high values for different settings that may affect the cluster's overall performance. The script will generate two files. One called **log.txt** which simply logs the tests as they are run. Checking this file will give the script runner an idea of the progress so far. 

The other files created by the Python test script will be in the **results** subdirectory.  The names of each file will correspond to the setting that was tested on each iteration, followed by either '.max' or '.min'. This determines whether the minimal or the maximum value was tested. The cluster will be restarted before each test and its configuration updated with the **start-cluster2.sh** and **make-tmpl.sh** scripts.

## Hadoop configuration files

While Hadoop has this documentation on their project website, it is included here to help with configuration.  Hadoop's main configuration files are: 

1. **core-site.xml** - has settings to describe the location of the master node and user group mappings.
2. **yarn-site.xml** - These settings affect performance of the cluster as a whole. This is also where either FairScheduler and CapacityScheduler are configured.
3. **mapred-site.xml** - These settings affect the performance and monitoring of jobs submitted to Hadoop as well as performance. This file is important to configure correctly on the machine which submits the job, even if that machine is not part of the cluster.
4. **hdfs-site.xml** - configuration for HDFS. 
5. **capacity-scheduler.xml** - contains settings for the CapacityScheduler. Only used if CapacityScheduler is enabled on **yarn-site.xml**. These settings may affect performance so tweaking them may be necessary to obtain better results.

## CapacityScheduler vs. FairScheduler ##

According to Hadoop docs, CapacityScheduler is a scheduler used to distribute cluster resources in a multi-tenant, multi organization cluster. FairScheduler is a scheduler designed to maximize resource use by distributing resources in equal parts to each running task. One task would have the full resources of the cluster, while two would have 50% of the resources of the cluster.  CapacityScheduler is enabled by default. To enable FairScheduler, uncomment the settings for yarn.resourcemanager.scheduler.class in **yarn-site-xml.tmpl** before running start-cluster.sh


## Our findings

Different configurations were tested, from which we can conlude the following:

1. CapacityScheduler delivers better performance than FairScheduler.
2. If the master node is also used as a slave, several of Hadoop's components crash or stop working after running several jobs.  We were able to achieve a stable node only after removing the master node as a "slave". However, there is no problem if the master node also acts as an HDFS datanode.
3. Jobs can be submitted via a machine that is not part of the cluster. It must have the hadoop installation and the configuration files with the settings that are IP Addresses pointing to the IP Address of the master slave.

## Best test (evaluated by execution time)

----- TestDFSIO ----- : write
            Date & time: Sat Jun 13 06:14:27 PDT 2020
        Number of files: 100
 Total MBytes processed: 102400
      Throughput mb/sec: 15.37
 Average IO rate mb/sec: 15.76
  IO rate std deviation: 2.56
     Test exec time sec: 1763.03

This test was submitted from a server that was not part of the cluster, using FairScheduler, and using the configuration files in the **runner_config** folder. However, submitting jobs via the master node can produce much lower execution times.


----- TestDFSIO ----- : write
Date & time: Sat Jun 09 01:59:49 UTC 2020
Number of files: 100
Total MBytes processed: 102400
Throughput mb/sec: 34.07
Average IO rate mb/sec: 35.88
IO rate std deviation: 8.5
Test exec time sec: 535.06

This test was submitted via the master node itself, using the settings in the .tmpl files.