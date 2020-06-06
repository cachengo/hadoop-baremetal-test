#!/bin/sh

hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.10.0-tests.jar TestDFSIO \
        -write \
        -nrFiles 10 \
        -size 40GB \
        -resFile ~/ocampos/hadoop-baremetal-test/results/TestDFSIOResults.txt

hdfs dfs -rm -r -f /benchmarks
hdfs dfs -rm -r -f /tmp
~                                                                                                                                                            
~                                                                                
