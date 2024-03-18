#!/bin/bash

BSP_PATH=$PWD
BASE_PATH=$PATH
TOOLCHAINS_PATH=/home/sdkuser/rtd1296-toolchains/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin
UBOOT_TOOLCHAIN_PATH=/home/sdkuser/rtd1296-toolchains/asdk64-4.9.4-a53-EL-3.10-g2.19-a64nt-160307/bin
UBOOT_PATH=/home/sdkuser/rtd1296-u-boot
IMAGE_BUILDER_PATH=/home/sdkuser/image-builder
FEED_PATH=$IMAGE_BUILDER_PATH/feed
CON_PATH=$BASE_PATH:$TOOLCHAINS_PATH:$UBOOT_TOOLCHAIN_PATH
KERNEL_PATH=/home/sdkuser/rtd1296-kernel
ROOTFS_PATH=/home/sdkuser/rtl1296-rootfs/rootfs
PROCESSOR=`cat /proc/cpuinfo | grep processor | wc -l`

function init()
{
    	sudo docker build --tag zang_1296:16.04 $BSP_PATH
	if [ ! -d rtd1296-kernel ];then
            git clone git@gitee.com:styt_1/rtd1296-kernel.git
    	else
            cd rtd1296-kernel && git pull origin
    	fi
    	cd $BSP_PATH
    	if [ ! -d rtd1296-toolchains ]; then
            git clone git@gitee.com:styt_1/rtd1296-toolchains.git
    	else
            cd rtd1296-toolchains && git pull origin
    	fi
	cd $BSP_PATH
	if [ ! -d rtl1296-rootfs ]; then
            git clone git@gitee.com:styt_1/rtl1296-rootfs.git
    	else
            cd rtl1296-rootfs && git pull origin
    	fi
    	cd $BSP_PATH
	if [ ! -d rtd1296-u-boot ]; then
            git clone git@gitee.com:styt_1/rtd1296-u-boot.git
        else
            cd rtd1296-u-boot && git pull origin
        fi
	cd $BSP_PATH
	if [ ! -d image-builder ]; then
            git clone git@gitee.com:styt_1/image-builder.git
        else
            cd image-builder && git pull origin
        fi
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
	cp rtd1296-kernel/.config rtd1296-kernel/arch/arm64/configs/zang_nas_defconfig
}

function clean()
{
	sudo docker run -it --rm --user sdkuser -v $BSP_PATH:/home/sdkuser \
                -e PATH=$CON_PATH \
                zang_1296:16.04 bash -c "cd $KERNEL_PATH && \
                make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 clean -j$((PROCESSOR*2))"
}

function ubuntu()
{
	cd rtl1296-rootfs
	sudo ./build_ubuntu_rootfs.sh
	cd -
}

function modules_install()
{
	sudo docker run -it --rm --user root -v $BSP_PATH:/home/sdkuser \
                -e PATH=$CON_PATH \
                zang_1296:16.04 bash -c "cd $KERNEL_PATH && \
                make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 INSTALL_MOD_PATH=$ROOTFS_PATH modules_install -j$((PROCESSOR*2))"
}

function make_uboot()
{
	sudo docker run -it --rm --user sdkuser -v $BSP_PATH:/home/sdkuser \
                -e PATH=$CON_PATH \
                zang_1296:16.04 bash -c "cd $UBOOT_PATH && \
		./build.sh RTD129x_emmc"
	if [ ! -d out/uboot ];then
		mkdir -p out/uboot
	else
		rm -rf out/uboot/*
	fi
	cp -rf rtd1296-u-boot/DVRBOOT_OUT/RTD129x_emmc out/uboot
}

function pack_img()
{
	sudo docker run -it --rm --user sdkuser -v $BSP_PATH:/home/sdkuser \
                -e PATH=$CON_PATH \
                zang_1296:16.04 bash -c "cd $IMAGE_BUILDER_PATH && ls &&\
                ./build_image.sh $FEED_PATH rtd129x_emmc"
	if [ ! -d out/ ];then
		mkdir -p out/
	else
		rm -rf out/install.img
	fi
	cp image-builder/install.img out/
}

function make_debian()
{
        cd rtl1296-rootfs
        git checkout debian
        sudo ./build_debian_rootfs.sh rootfs
        cd -
	modules_install
	cd rtl1296-rootfs
	sudo ./build_debian_rootfs.sh pack
	cd -
}

case "$1" in
  "init")
	  init
    ;;
  "kernel")
	  make_kernel
    ;;
  "uboot")
	  make_uboot
    ;;
  "kernel_menuconfig")
  	  kernel_menuconfig	
    ;;
  "clean")
	  clean
    ;;
  "ubuntu")
	  ubuntu
	  modules_install
    ;;
  "modules_install")
  	modules_install
    ;;
  "pack_img")
       pack_img
    ;;
  "debian")
       make_kernel
       make_debian
    ;;
  *)
    echo "未知选项: $1"
    ;;
esac
