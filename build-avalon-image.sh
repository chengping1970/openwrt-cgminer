#!/bin/bash
# This is a script for build avalon controller image
#
#  Copyright 2017 Yangjun <yangjun@canaan-creative.com>
#  Copyright 2014-2017 Mikeqin <Fengling.Qin@gmail.com>
#  Copyright 2012-2015 Xiangfu <xiangfu@openmobilefree.com>
#
# OPENWRT_DIR is ${ROOT_DIR}/openwrt, build the image in it
# Controller's image should include the following configurations:
#    ${AVA_MACHINE}_owrepo : OpenWrt repo, format: repo_url@repo_ver
#    feeds.${AVA_MACHINE}.conf : OpenWrt feeds, file locate in cgminer-openwrt-packages
#    ${AVA_TARGET_BOARD}_brdcfg : OpenWrt target and config, file locate in cgminer-openwrt-packages
#
# Learn bash: http://explainshell.com/
set -e

SCRIPT_VERSION=20190102

# Support machine: avalon6, avalon4, abc, avalon7, avalon8
[ -z "${AVA_MACHINE}" ] && AVA_MACHINE=avalon9

# Support target board: rpi3-modelb, rpi2-modelb, rpi1-modelb, tl-wr703n-v1, tl-mr3020-v1, wrt1200ac, zedboard, h3, zctrl, xc7z100
[ -z "${AVA_TARGET_BOARD}" ] && AVA_TARGET_BOARD=h3

# Patch repo
[ -z "${PATCH_REPO}" ] && PATCH_REPO=Canaan-Creative

# OpenWrt repo
avalon4_owrepo="svn://svn.openwrt.org/openwrt/trunk@43076"
avalon6_owrepo="git://github.com/chengping1970/openwrt.git"
abc_owrepo="git://git.openwrt.org/openwrt.git"
avalon7_owrepo="git://github.com/chengping1970/openwrt.git"
avalon8_owrepo="git://github.com/chengping1970/openwrt.git"
avalon9_owrepo="git://github.com/chengping1970/openwrt.git"

# DEFINE enable A920
[ -z "${ENABLE_A920}" ] && ENABLE_A920=disable

#defiine network 
[ -z "${AVA_NETWORK}" ] && AVA_NETWORK=default

# DEFINE debug
[ -z "${DEBUG}" ] && DEBUG=no

#define feature
[ -z "${FEATURE}" ] && FEATURE=none

# OpenWrt feeds, features: NULL(Default), NiceHash, DHCP, bitcoind
[ "${FEATURE}" == "none" ] && FEEDS_CONF_URL=https://raw.github.com/Canaan-Creative/cgminer-openwrt-packages/master/cgminer/data/feeds.${AVA_MACHINE}.conf
[ "${FEATURE}" == "NiceHash" ] && FEEDS_CONF_URL=https://raw.github.com/Canaan-Creative/cgminer-openwrt-packages/xnsub/cgminer/data/feeds.${AVA_MACHINE}.conf
[ "${FEATURE}" == "DHCP" ] && FEEDS_CONF_URL=https://raw.github.com/Canaan-Creative/cgminer-openwrt-packages/dhcp/cgminer/data/feeds.${AVA_MACHINE}.conf
[ "${FEATURE}" == "bitcoind" ] && FEEDS_CONF_URL=https://raw.github.com/Canaan-Creative/cgminer-openwrt-packages/bitcoind/cgminer/data/feeds.${AVA_MACHINE}.conf

# Board config: target(get it in the OpenWrt bin), config
rpi3_modelb_brdcfg=("brcm2708/bcm2710" "config.${AVA_MACHINE}.rpi3")
rpi2_modelb_brdcfg=("brcm2708" "config.${AVA_MACHINE}.rpi2")
rpi1_modelb_brdcfg=("brcm2708" "config.${AVA_MACHINE}.raspberry-pi")
tl_wr703n_v1_brdcfg=("ar71xx" "config.${AVA_MACHINE}.703n")
tl_mr3020_v1_brdcfg=("ar71xx" "config.${AVA_MACHINE}.mr3020")
wrt1200ac_brdcfg=("mvebu" "config.${AVA_MACHINE}.wrt1200ac")
zedboard_brdcfg=("zynq" "config.${AVA_MACHINE}.zedboard")
zctrl_brdcfg=("zynq" "config.${AVA_MACHINE}.zctrl")
xc7z100_brdcfg=("zynq" "config.7z100")
h3_brdcfg=("sunxi/cortexa7" "config.${AVA_MACHINE}.h3")

which wget > /dev/null && DL_PROG=wget && DL_PARA="-nv -O"
which curl > /dev/null && DL_PROG=curl && DL_PARA="-L -o"

# According to http://wiki.openwrt.org/doc/howto/build
unset SED
unset GREP_OPTIONS
[ "`id -u`" == "0" ] && echo "[ERROR]: Please use non-root user" && exit 1
# Adjust CORE_NUM by yourself
[ -z "${CORE_NUM}" ] && CORE_NUM="$(expr $(nproc) + 1)"
DATE=`date +%Y%m%d`
START_TIME=`date "+%Y-%m-%d %H:%M:%S"`
SCRIPT_FILE="$(readlink -f $0)"
SCRIPT_DIR=`dirname ${SCRIPT_FILE}`
ROOT_DIR=${SCRIPT_DIR}/avalon
OPENWRT_DIR=${ROOT_DIR}/openwrt

prepare_version() {
    cd ${OPENWRT_DIR}
    if [ "${AVA_MACHINE}" == "avalon7" ]; then
        GIT_VERSION=`git ls-remote https://github.com/Canaan-Creative/cgminer master | cut -f1 | cut -c1-7`
    elif [ "${AVA_MACHINE}" == "avalon8" ]; then
        GIT_VERSION=`git ls-remote https://github.com/Canaan-Creative/cgminer avalon8 | cut -f1 | cut -c1-7`
    elif [ "${AVA_MACHINE}" == "avalon8_lp" ]; then
        GIT_VERSION=`git ls-remote https://github.com/Canaan-Creative/cgminer avalon8_lp | cut -f1 | cut -c1-7`
    elif [ "${AVA_MACHINE}" == "avalon9" ]; then
        if [ "${ENABLE_A920}" == "disable" ]; then
            GIT_VERSION=`git ls-remote https://github.com/Canaan-Creative/cgminer avalon9 | cut -f1 | cut -c1-7`
        else
            GIT_VERSION=`git ls-remote https://github.com/Canaan-Creative/cgminer avalon9-dev | cut -f1 | cut -c1-7`
        fi
    elif [ "${AVA_MACHINE}" == "avalon911" ]; then
        GIT_VERSION=`git ls-remote https://github.com/Canaan-Creative/cgminer avalon911 | cut -f1 | cut -c1-7`
    elif [ "${AVA_MACHINE}" == "avalonlc3" ]; then
        GIT_VERSION=`git ls-remote https://github.com/Canaan-Creative/cgminer avalonlc3 | cut -f1 | cut -c1-7`
    else
        GIT_VERSION=`git ls-remote https://github.com/Canaan-Creative/cgminer avalon4 | cut -f1 | cut -c1-7`
    fi
    LUCI_GIT_VERSION=`git --git-dir=./feeds/luci/.git rev-parse HEAD | cut -c1-7`
    OW_GIT_VERSION=`git --git-dir=./feeds/cgminer/.git rev-parse HEAD | cut -c1-7`

    cat > ./files/etc/avalon_version << EOL
$AVA_MACHINE - $DATE
    luci: $LUCI_GIT_VERSION
    cgminer: $GIT_VERSION
    cgminer-packages: $OW_GIT_VERSION
EOL
}

prepare_config() {
    cd ${OPENWRT_DIR}

    if [ "${AVA_TARGET_BOARD}" == "zctrl" ]; then
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/zctrl-miscs/patches/linux/zynq/config-4.4 -O ./target/linux/zynq/config-4.4
    fi

    if [ "${AVA_TARGET_BOARD}" == "xc7z100" ]; then
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/7z100-miscs/patches/linux/zynq/config-4.4 -O ./target/linux/zynq/config-4.4
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/7z100-miscs/config.7z100 -O ./feeds/cgminer/cgminer/data/config.7z100
    fi

    eval OPENWRT_CONFIG=\${"`echo ${AVA_TARGET_BOARD//-/_}`"_brdcfg[1]} && cp ./feeds/cgminer/cgminer/data/${OPENWRT_CONFIG} .config
}

prepare_patch() {
    cd ${OPENWRT_DIR}

    if [ "${AVA_TARGET_BOARD}" == "zctrl" ]; then
	# Patch U-Boot
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/zctrl-miscs/patches/u-boot/Makefile -O ./package/boot/uboot-zynq/Makefile
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/zctrl-miscs/patches/u-boot/001-use-dtc-in-kernel.patch -O ./package/boot/uboot-zynq/patches/001-use-dtc-in-kernel.patch
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/zctrl-miscs/patches/u-boot/030-add-dts-for-zctrl.patch -O ./package/boot/uboot-zynq/patches/030-add-dts-for-zctrl.patch
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/zctrl-miscs/patches/u-boot/031-update-ddr-for-zctrl.patch -O ./package/boot/uboot-zynq/patches/031-update-ddr-for-zctrl.patch
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/zctrl-miscs/patches/u-boot/032-add-defconfig-for-zctrl.patch -O ./package/boot/uboot-zynq/patches/032-add-defconfig-for-zctrl.patch

	# Patch Linux
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/zctrl-miscs/patches/linux/zynq/image/Makefile -O ./target/linux/zynq/image/Makefile
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/zctrl-miscs/patches/linux/zynq/patches/120-add-dts-for-zctrl.patch -O ./target/linux/zynq/patches/120-add-dts-for-zctrl.patch
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/zctrl-miscs/patches/linux/zynq/profiles/zctrl.mk -O ./target/linux/zynq/profiles/zctrl.mk
    fi

    if [ "${AVA_TARGET_BOARD}" == "xc7z100" ]; then
	# Patch U-Boot
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/7z100-miscs/patches/u-boot/Makefile -O ./package/boot/uboot-zynq/Makefile
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/7z100-miscs/patches/u-boot/001-use-dtc-in-kernel.patch -O ./package/boot/uboot-zynq/patches/001-use-dtc-in-kernel.patch
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/7z100-miscs/patches/u-boot/040-add-dts-for-7z100.patch -O ./package/boot/uboot-zynq/patches/040-add-dts-for-7z100.patch
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/7z100-miscs/patches/u-boot/041-update-init-cfg-for-7z100.patch -O ./package/boot/uboot-zynq/patches/041-update-init-cfg-for-7z100.patch
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/7z100-miscs/patches/u-boot/042-add-defconfig-for-7z100.patch -O ./package/boot/uboot-zynq/patches/042-add-defconfig-for-7z100.patch

	# Patch Linux
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/7z100-miscs/patches/linux/zynq/image/Makefile -O ./target/linux/zynq/image/Makefile
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/7z100-miscs/patches/linux/zynq/patches/121-add-dts-for-7z100.patch -O ./target/linux/zynq/patches/121-add-dts-for-7z100.patch
        wget https://raw.githubusercontent.com/${PATCH_REPO}/Avalon-extras/master/7z100-miscs/patches/linux/zynq/profiles/7z100.mk -O ./target/linux/zynq/profiles/7z100.mk
    fi
}

prepare_feeds() {
    cd ${OPENWRT_DIR}
    if [ "${AVA_MACHINE}" == "avalon6" ]; then
        cp ../../feeds.conf.avalon6 feeds.conf && \
        ./scripts/feeds update -a && \
        ./scripts/feeds install -a
    else
        $DL_PROG ${FEEDS_CONF_URL} $DL_PARA feeds.conf && \
        ./scripts/feeds update -a && \
        ./scripts/feeds install -a
    fi

    if [ ! -e files ]; then
        ln -s feeds/cgminer/cgminer/root-files files
    fi
    
    alias cp='cp -i'
    unalias cp
    cp ../../config.avalon9.h3 feeds/cgminer/cgminer/data
    cp ../../config.avalon911.h3 feeds/cgminer/cgminer/data
    cp ../../config.avalonlc3.h3 feeds/cgminer/cgminer/data
    cp ../../network.single.${AVA_NETWORK} feeds/cgminer/cgminer/root-files/etc/config/network
    cp ../../dhcp.single.${AVA_NETWORK} feeds/cgminer/cgminer/root-files/etc/config/dhcp
    if [ "${AVA_MACHINE}" == "avalon9" ] && [ "${ENABLE_A920}" == "enable" ]; then
        cp ../../Makefile.avalon920 feeds/cgminer/cgminer/Makefile
    else
        cp ../../Makefile feeds/cgminer/cgminer/Makefile
    fi
}

prepare_source() {
    echo "Gen firmware for ...... [DEBUG:$DEBUG FATURE:$FEATURE] GCC-5.5.0"
    echo "TARGET BOARD   :${AVA_TARGET_BOARD}"
    echo "TARGET MACHINE :${AVA_MACHINE}"
    echo "ENABLE_A920    :${ENABLE_A920}"
    echo "NETWORK        :${AVA_NETWORK}"
    cd ${SCRIPT_DIR}
    [ ! -d avalon ] && mkdir -p avalon/bin
    cd avalon
    if [ ! -d openwrt ]; then
        eval OPENWRT_URL=\${${AVA_MACHINE}_owrepo}
        PROTOCOL="`echo ${OPENWRT_URL} | cut -d : -f 1`"

        case "${PROTOCOL}" in
            git)
                GITBRANCH="`echo ${OPENWRT_URL} | cut -s -d @ -f 2`"
                GITREPO="`echo ${OPENWRT_URL} | cut -d @ -f 1`"
                [ -z ${GITBRANCH} ] && GITBRANCH=master
                git clone ${GITREPO} openwrt
                cd openwrt && git checkout ${GITBRANCH}
                cd ..
                ;;
            svn)
                SVNVER="`echo ${OPENWRT_URL} | cut -s -d @ -f 2`"
                SVNREPO="`echo ${OPENWRT_URL} | cut -d @ -f 1`"
                if [ -z ${SVNVER} ]; then
                    svn co ${SVNREPO}@${SVNVER} openwrt
                else
                    svn co ${SVNREPO} openwrt
                fi
                ;;
            *)
                echo "Protocol not supported"; exit 1;
                ;;
        esac
    fi
    [ ! -e dl ] && ln -s ../../download dl
    cd ${OPENWRT_DIR}
    ln -sf ../dl
}

build_image() {
    cd ${OPENWRT_DIR}
    yes "" | make oldconfig > /dev/null    

    # clean before build
    make clean
    
    if [ "${DEBUG}" == "log" ]; then
        make -j1 V=s > log.txt 2>&1
    elif [ "${DEBUG}" == "yes" ]; then
        make -j1 V=s
    elif [ "${DEBUG}" == "message" ]; then
        make -j${CORE_NUM} V=s
    else
        make -j${CORE_NUM} clean world
    fi
}

build_cgminer() {
    cd ${OPENWRT_DIR}
    rm -f ./dl/cgminer-*-avalon*.tar.bz2
    yes "" | make oldconfig > /dev/null
    make -j${CORE_NUM} package/cgminer/{clean,compile}
    if [ "$?" == "0" ]; then
        eval AVA_TARGET_PLATFORM=\${"`echo ${AVA_TARGET_BOARD//-/_}`"_brdcfg[0]}
        cd ..
        mkdir -p ./bin/${AVA_TARGET_BOARD}
        cp ./openwrt/bin/targets/${AVA_TARGET_PLATFORM}/packages/cgminer/cgminer*.ipk  ./bin/${AVA_TARGET_BOARD}
    fi
}

do_release() {
    cd ${ROOT_DIR}
    eval AVA_TARGET_PLATFORM=\${"`echo ${AVA_TARGET_BOARD//-/_}`"_brdcfg[0]}
    if [ "${AVA_MACHINE}" == "avalon9" ] && [ "${ENABLE_A920}" == "enable" ]; then
        mkdir -p ./bin/${DATE}/${AVA_MACHINE}20.${AVA_TARGET_BOARD}/
        cp -a ./openwrt/bin/targets/${AVA_TARGET_PLATFORM}/* ./bin/${DATE}/${AVA_MACHINE}20.${AVA_TARGET_BOARD}/
    else
        mkdir -p ./bin/${DATE}/${AVA_MACHINE}.${AVA_TARGET_BOARD}/
        cp -a ./openwrt/bin/targets/${AVA_TARGET_PLATFORM}/* ./bin/${DATE}/${AVA_MACHINE}.${AVA_TARGET_BOARD}/
    fi
    # write image info
    END_TIME=`date "+%Y-%m-%d %H:%M:%S"`
    if [ "${AVA_MACHINE}" == "avalon9" ] && [ "${ENABLE_A920}" == "enable" ]; then
        cd ./bin/${DATE}/${AVA_MACHINE}20.${AVA_TARGET_BOARD}
    else
        cd ./bin/${DATE}/${AVA_MACHINE}.${AVA_TARGET_BOARD}
    fi
    cat > ./image.info << EOL
GCC-VER  :5.5.0
FEATURE  :${FEATURE}
POOL     :${AVA_POOL}
NETWROK  :${AVA_NETWORK}
START    :${START_TIME}
END      :${END_TIME}
EOL
}

cleanup() {
    cd ${ROOT_DIR}
    rm -rf openwrt/ > /dev/null
}

show_help() {
    echo "\
Usage: $0 [--version] [--help] [--build] [--cgminer] [--cleanup]

     --version
     --help             Display help message

     --build            Get .config file and build firmware

     --cgminer          Re-compile only cgminer openwrt package

     --cleanup          Remove all files

     AVA_TARGET_BOARD   Environment variable, available target:
                        rpi3-modelb, rpi2-modelb
                        rpi1-modelb, tl-mr3020-v1
                        zctrl, xc7z100, h3
                        use h3 if unset
     AVA_NETWORK	    Environment variable, available network:
                        default, other, wifi
                        use default if unset
     AVA_MACHINE        Environment variable, available machine:
                        avalonlc3, avalon9, avalon911, avalon8, avalon8_lp, avalon7, avalon6, avalon4
                        use avalon9 if unset
     ENABLE_A920        Environment variable, available A920:
                        diasble, enable
                        use disable if unset
     FEATURE            Environment variable, available feature:
                        none, NiceHash, DHCP, bitcoind
                        use none if unset
     DEBUG              Environment variable, available feature:
                        yes, no, message, log 
                        use no if unset
Example:
     for avalon7 ,default IP 192.168.7.234
     AVA_TARGET_BOARD=h3 AVA_NETWORK=other AVA_MACHINE=avalon7 FEATURE=NiceHash DEBUG=message ./build-avalon-image.sh --build
     for avalon8
     AVA_TARGET_BOARD=h3 AVA_NETWORK=default AVA_MACHINE=avalon8 FEATURE=none DEBUG=no ./build-avalon-image.sh --build
     for avalon9
     AVA_TARGET_BOARD=h3 AVA_NETWORK=default AVA_MACHINE=avalon9 ENABLE_A920=disable FEATURE=none DEBUG=no ./build-avalon-image.sh --build

Written by: Xiangfu <xiangfu@openmobilefree.net>
            Fengling <Fengling.Qin@gmail.com>
            Yangjun <yangjun@canaan-creative.com>
            xuzhenxing <xuzhenxing@canaan-creative.com>
            chengping <13641793410@163.com>
                                                     Version: ${SCRIPT_VERSION}"
 }

if [ "$#" == "0" ]; then
    $0 --help
    exit 0
fi

for i in "$@"
do
    case $i in
        --version|--help)
            show_help
            exit
            ;;
        --build)
            prepare_source && prepare_feeds && prepare_patch && prepare_config && prepare_version && build_image && do_release
            ;;
        --cgminer)
            prepare_source && prepare_feeds && prepare_config && prepare_version && build_cgminer
            ;;
        --cleanup)
            cleanup
            ;;
        *)
            show_help
            exit
            ;;
    esac
done

# vim: set ts=4 sw=4 et

