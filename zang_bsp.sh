#!/bin/bash

case "$1" in
  "init")
    if [ ! -d rtd1296-kernel ];then
	    git clone git@gitee.com:styt_1/rtd1296-kernel.git
    else
	    cd rtd1296-kernel && git pull origin
    fi
    if [ ! -d rtd1296-toolchains ]; then
	    git clone git@gitee.com:styt_1/rtd1296-toolchains.git
    else
	    cd toolchains && git pull origin
    fi
    sudo docker build --tag zang_1296:16.04 .
    ;;
  *)
    echo "未知选项: $1"
    ;;
esac
