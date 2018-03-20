#!/bin/bash
#
# Copyright 2016 cmeng
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -u
source ./_shared.sh

# Setup architectures, library name and other vars + cleanup from previous runs
LIB_GIT="v1.7.0"
LIB_VPX="libvpx-1.7.0"
LIB_DEST_DIR=${BASEDIR}/libs

#[ -d ${LIB_DEST_DIR} ] && rm -rf ${LIB_DEST_DIR}
[ -f "${LIB_GIT}.tar.gz" ] || wget https://github.com/webmproject/libvpx/archive/${LIB_GIT}.tar.gz;

# Unarchive library, then configure and make for specified architectures
configure_make() {
  ARCH=$1; ABI=$2;

# rm -rf "${LIB_VPX}"
# tar xfz "${LIB_GIT}.tar.gz" "${LIB_VPX}"
[ -d "${LIB_VPX}" ] || tar xfz "${LIB_GIT}.tar.gz" "${LIB_VPX}";

  pushd "${LIB_VPX}"
  make clean

  configure $*

  if [ "$ARCH" == "android" ]; then
      TARGET="armv7-android-gcc --disable-neon --disable-neon-asm"
  elif [ "$ARCH" == "android-armeabi" ]; then
      TARGET="armv7-android-gcc"
  elif [ "$ARCH" == "android64-aarch64" ]; then
      TARGET="arm64-android-gcc"
  elif [ "$ARCH" == "android-x86" ]; then
      TARGET="x86-android-gcc"
  elif [ "$ARCH" == "android64" ]; then
      TARGET="x86_64-android-gcc"
  elif [ "$ARCH" == "android-mips" ]; then
      TARGET="mips32-linux-gcc"
  elif [ "$ARCH" == "android-mips64" ]; then
      TARGET="mips64-linux-gcc"
  fi;

  # --sdk-path=${TOOLCHAIN_PREFIX} must use ${NDK} actual path else cannot find CC for arm64-android-gcc
  # https://bugs.chromium.org/p/webm/issues/detail?id=1476
  # --extra-cflags fix for r16b; but essentially NOP for NDK below r16 but failed arm64-android-gcc

  ./configure \
    --sdk-path=${NDK} \
    --prefix=${PREFIX} \
    --target=${TARGET} \
    --disable-runtime-cpu-detect \
    --disable-docs \
    --enable-static \
    --disable-shared \
    --disable-examples \
    --disable-tools \
    --disable-debug \
    --disable-unit-tests \
    --enable-realtime-only \
    --disable-webm-io \
#    --extra-cflags="-isystem ${NDK}/sysroot/usr/include/${NDK_ABIARCH} -isystem ${NDK}/sysroot/usr/include"

  if make -j4; then
    make install

    [ -d ${PREFIX}/include ] || mkdir -p ${PREFIX}/include/vpx \
	&& mkdir -p ${PREFIX}/include/common \
	&& mkdir -p ${PREFIX}/include/mkvmuxer \
	&& mkdir -p ${PREFIX}/include/mkvparser \
	&& mkdir -p ${PREFIX}/include/libmkv
    cp -r ./third_party/libwebm/common/*.h ${PREFIX}/include/common
    cp -r ./third_party/libwebm/mkvmuxer/*.h ${PREFIX}/include/mkvmuxer
    cp -r ./third_party/libwebm/mkvparser/*.h ${PREFIX}/include/mkvparser    
    # cp -r ./third_party/libmkv/*.h ${PREFIX}/include/libmkv
  fi;
  popd

}

for ((i=0; i < ${#ARCHS[@]}; i++))
do
  if [[ $# -eq 0 ]] || [[ "$1" == "${ARCHS[i]}" ]]; then
    # Do not build 64 bit arch if ANDROID_API is less than 21 which is
    # the minimum supported API level for 64 bit.
    [[ ${ANDROID_API} < 21 ]] && ( echo "${ABIS[i]}" | grep 64 > /dev/null ) && continue;
    configure_make "${ARCHS[i]}" "${ABIS[i]}"
  fi
done
