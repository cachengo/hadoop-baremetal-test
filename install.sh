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
set -e

apt-get update
apt-get install -y openjdk-8-jdk
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment

# Change this next line to install elsewhere
cd ~
rm -rf ./hadoop
VERSION=2.8.5
wget https://archive.apache.org/dist/hadoop/common/hadoop-$VERSION/hadoop-$VERSION.tar.gz
tar -xzf hadoop-$VERSION.tar.gz
mv hadoop-$VERSION ./hadoop
rm hadoop-$VERSION.tar.gz
sed -i 's;${JAVA_HOME};'"$JAVA_HOME;g" ./hadoop/etc/hadoop/hadoop-env.sh
HADOOP_HOME=`pwd`/hadoop
echo "HADOOP_HOME=$HADOOP_HOME" >> /etc/environment
PATH="${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${JAVA_HOME}/bin:${PATH}"
echo PATH=$PATH >> /etc/environment

mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys

apt-get update
apt-get install -y --no-install-recommends autoconf automake libtool curl make g++ unzip patch cmake zlib1g zlib1g-dev libsnappy-dev maven pkgconf libssl1.0-dev libbz2-dev
cd /
export PROTOC_VERSION=2.5.0
git clone https://github.com/google/protobuf.git
cd /protobuf
git checkout v$PROTOC_VERSION
wget https://raw.githubusercontent.com/cachengo/hadoop-docker/master/protobuf-2.5.0-arm64.patch
patch -p1 < ./protobuf-2.5.0-arm64.patch
curl $curlopts -L -O https://github.com/google/googletest/archive/release-1.7.0.zip
unzip -q release-1.7.0.zip
rm release-1.7.0.zip
mv googletest-release-1.7.0 gtest
./autogen.sh
./configure
make
make install
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
echo /usr/local/lib >> /etc/ld.so.conf
ldconfig
rm -rf /protobuf

. /etc/environment
cd /
rm -rf /hadoop
git clone https://github.com/apache/hadoop.git
cd /hadoop
git checkout branch-$VERSION
sudo mvn package -Pdist,native -DskipTests -Dtar
mkdir -p $HADOOP_HOME/lib/native
cp -r hadoop-dist/target/hadoop-$VERSION/lib/native/* $HADOOP_HOME/lib/native
cd ..
rm -rf /hadoop

echo "HADOOP_OPTS=-Djava.library.path=$HADOOP_HOME/lib/native" >> /etc/environment
echo "Successfully installed Hadoop"
