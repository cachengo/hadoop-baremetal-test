#!/bin/sh

hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.10.0-tests.jar TestDFSIO \
        -read \
        -nrFiles 5 \
        -size 20GB \
        -resFile ~/ocampos/hadoop-baremetal-test/results/TestDFSIOResults.txt
~                                                                                                                                                            
~                                                                                
