#!/bin/bash
echo -e "\n================ Updating libvpx ============================"

LIB_GIT="v1.7.0"
LIB_VPX="libvpx-1.7.0"

[ -f "${LIB_GIT}.tar.gz" ] || wget https://github.com/webmproject/libvpx/archive/${LIB_GIT}.tar.gz;
rm -rf "${LIB_VPX}"

echo "Extract ${LIB_VPX} file"
tar -xf "${LIB_GIT}.tar.gz" "${LIB_VPX}"

echo -e "======== Completed libvpx update ============================"

