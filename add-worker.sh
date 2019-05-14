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

ip="";
port="";
hostname="";

print_usage() {
  printf "Usage: ...";
}

while getopts 'h:a:p:' flag; do
  case "${flag}" in
    a) ip="${OPTARG}" ;;
    p) port="${OPTARG}" ;;
    h) hostname="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ "$hostname" = "" ]; then
  echo "Hostname not specified, use -h... exiting"
  exit 1
fi

# If the IP was specified add an entry to /etc/hosts
if [ "$ip" != "" ]; then
  echo "$ip $hostname" >> /etc/hosts
fi

# If the port was specified add it to ssh_config
if [ "$port" != "" ]; then
  file=~/.ssh/config
  echo "Host $hostname" >> $file
  echo "    Hostname $hostname" >> $file
  echo "    User root" >> $file
  echo "    Port $port" >> $file
fi

echo $hostname >> $HADOOP_HOME/etc/hadoop/slaves
start-dfs.sh
