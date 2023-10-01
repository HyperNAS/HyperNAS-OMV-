#!/bin/bash

BSP_PATH=$PWD
BASE_PATH=$PATH
TOOLCHAINS_PATH=/home/sdkuser/rtd1296-toolchains/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin
UBOOT_TOOLCHAIN_PATH=/home/sdkuser/rtd1296-toolchains/asdk64-4.9.4-a53-EL-3.10-g2.19-a64nt-160307/bin
CON_PATH=$BASE_PATH:$TOOLCHAINS_PATH:$UBOOT_TOOLCHAIN_PATH
KERNEL_PATH=/home/sdkuser/rtd1296-kernel
PROCESSOR=`cat /proc/cpuinfo | grep processor | wc -l`

function init()
{
	if [ ! -d rtd1296-kernel ];then
            git clone git@gitee.com:styt_1/rtd1296-kernel.git
    	else
            cd rtd1296-kernel && git pull origin
    	fi
    	cd $BSP_PATH
    	if [ ! -d rtd1296-toolchains ]; then
            echo yes
            git clone git@gitee.com:styt_1/rtd1296-toolchains.git
    	else
            echo no
            cd toolchains && git pull origin
    	fi
    	cd $BSP_PATH
    	sudo docker build --tag zang_1296:16.04 .
}

function make_kernel()
{
    	sudo docker run -it --rm --user sdkuser -v $BSP_PATH:/home/sdkuser \
            	-e PATH=$CON_PATH \
            	zang_1296:16.04 bash -c "cd $KERNEL_PATH && \
            	make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 zang_nas_defconfig && \
            	make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 -j$((PROCESSOR*2))"
	if [ ! -d out ];then
		mkdir -p out/kernel/dtb
	else
		rm -rf out/kernel/*
		mkdir -p out/kernel/dtb
	fi
	cp rtd1296-kernel/arch/arm64/boot/Image out/kernel
	cp -rf rtd1296-kernel/arch/arm64/boot/dts/realtek/rtd129x/*.dtb out/kernel
}

function kernel_menuconfig()
{
	sudo docker run -it --rm --user sdkuser -v $BSP_PATH:/home/sdkuser \
                -e PATH=$CON_PATH \
                zang_1296:16.04 bash -c "cd $KERNEL_PATH && \
                make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 menuconfig -j$((PROCESSOR*2))"
	cp rtd1296-kernel/.config rtd1296-kernel/arch/arm64/configs
}

case "$1" in
  "init")
	  init
    ;;
  "kernel")
	  make_kernel
    ;;
  "kernel_menuconfig")
  	  kernel_menuconfig	
    ;;
  *)
    echo "未知选项: $1"
    ;;
esac
