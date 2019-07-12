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

if [ ! -f "$HOME/.ssh/ssh_config" ]; then
  echo "Host * " >> $HOME/.ssh/config
  echo "  UserKnownHostsFile /dev/null" >> $HOME/.ssh/config
  echo "  StrictHostKeyChecking no" >> $HOME/.ssh/config
  sudo /etc/init.d/ssh restart
fi

if [ ! -f "$HOME/.ssh/id_rsa" ]; then
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi
