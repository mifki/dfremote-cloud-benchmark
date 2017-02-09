#!/bin/bash
fallocate -l 4G /swp ; chmod 600 /swp ; mkswap /swp ; swapon /swp ; echo '/swp none swap sw 0 0' >>/etc/fstab
apt install unzip
wget https://github.com/mifki/dfremote-cloud-benchmark/raw/master/benchmark.lua
wget http://mifki.com/a/t/gloveloved.zip
unzip gloveloved.zip -d save/
docker run --name=df -dt -v $PWD/save:/df_linux/data/save -v $PWD/benchmark.lua:/df_linux/hack/scripts/benchmark.lua mifki/dfremote
sleep 5
docker exec df /df_linux/dfhack-run benchmark df
