touch $HADOOP_HOME/etc/hadoop/workers

if [ ! -f "$HOME/.ssh/id_rsa" ]; then
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
fi
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys

echo "Starting the master node..."

# format namenode
hdfs namenode -format -force
