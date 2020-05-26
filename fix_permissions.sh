#!/bin/sh

set -e 
ssh-add
hosts=(
    fd61:3542:8c18:137c:7999:93de:a9cc:179e
    fd61:3542:8c18:137c:7999:93c5:c230:f66e
    fd61:3542:8c18:137c:7999:9375:c38f:f610   
    fd61:3542:8c18:137c:7999:932f:d373:b0c4
    fd61:3542:8c18:137c:7999:93e2:206c:a22e
    fd61:3542:8c18:137c:7999:9392:1f2a:8ff4
    fd61:3542:8c18:137c:7999:9340:3194:3909

)

for i in "${hosts[@]}"
do
    echo "Running install script on ${i}"
    ssh cachengo@$i 'sudo bash -s chmod a+wx ~/hadoop/etc/hadoop'
    ssh cachengo@$i 'sudo bash -s chown cachengo:cachengo ~/hadoop/etc/hadoop'
done

