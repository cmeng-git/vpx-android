#!/bin/bash
#
# Copyright 2016 Eng Chong Meng
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

# Uncomment the line below to see all script echo to terminal
# set -x

# export ANDROID_NDK="/opt/android/android-ndk-r15c" - last working is r15c without errors for aTalk
# r16b => Unable to invoke compiler: /opt/android/android-ndk-r16b/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-gcc but build?

if [[ $ANDROID_NDK = "" ]]; then
	echo "You need to set ANDROID_NDK environment variable, exiting"
	echo "Use: export ANDROID_NDK=/your/path/to/android-ndk"
	echo "e.g.: export ANDROID_NDK=/opt/android/android-ndk-r15c"
	exit 1
fi
set -u

# Never mix two api level to build static library for use on the same apk.
# Set to API:21 for aTalk 64-bit architecture support
# Does not build 64-bit arch if ANDROID_API is less than 21 i.e. the minimum supported API level for 64-bit.
ANDROID_API=21
NDK_ABI_VERSION=4.9

# Do not change naming convention of the ABIS; see:
# https://developer.android.com/ndk/guides/abis.html#Native code in app packages
# ABIS=("armeabi" "armeabi-v7a" "arm64-v8a" "x86" "x86_64" "mips" "mips64")

# Android recommended architecture support; others are deprecated
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
# ABIS=("arm64-v8a")

BASEDIR=`pwd`
NDK=${ANDROID_NDK}
HOST_NUM_CORES=$(nproc)

# https://gcc.gnu.org/onlinedocs/gcc-4.9.1/gcc/Optimize-Options.html
# Note: vpx with ABIs x86 and x86_64 build has error with option -fstack-protector-all
CFLAGS_="-fpic -fpie -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -fno-strict-overflow -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2"
# Enable report-all for earlier detection of errors instead at later stage
LDFLAGS_="-Wl,-z,defs -Wl,--unresolved-symbols=report-all"

# Do not modify any of the NDK_ARCH, CPU and -march unless you are sure.
# The settings are used by <ARCH>-linux-android-gcc and submodule configure
# https://en.wikipedia.org/wiki/List_of_ARM_microarchitectures
# $NDK/toolchains/llvm/prebuilt/...../includellvm/ARMTargetParser.def etc
# ARCH - should be one from $ANDROID_NDK/platforms/android-$API/arch-* [arm / arm64 / mips / mips64 / x86 / x86_64]"

configure() {
  ABI=$1;
  TOOLCHAIN_PREFIX=${BASEDIR}/${ABI}-android-toolchain

  case $ABI in
    # Deprecated in r16. Will be removed in r17
    armeabi)
      NDK_ARCH="arm"
      NDK_ABIARCH="arm-linux-androideabi"
      ARCH_FLAGS="-march=armv5 -marm -finline-limit=64"
      ARCH_LINK=""
      ASFLAGS=""
    ;;
    # Standalone toolchains error.
    # /home/cmeng/workspace/ndk/vpx-android/armeabi-v7a-android-toolchain/bin/arm-linux-androideabi-ld: -Wl,--fix-cortex-a8: unknown option
    armeabi-v7a)
      NDK_ARCH="arm"
      NDK_ABIARCH="arm-linux-androideabi"
      CFLAGS="${CFLAGS_} -march=armv7-a -mfloat-abi=softfp -mfpu=neon -mtune=cortex-a8 -mthumb -D__thumb__"
      LDFLAGS="${LDFLAGS_} -march=armv7-a -Wl,--fix-cortex-a8"
      ASFLAGS=""
    ;;
    arm64-v8a)
      # Valid cpu = armv8-a cortex-a35, cortex-a53, cortec-a57 etc. but -march=armv8-a is required
      # x264 build has own undefined references e.g. x264_8_pixel_sad_16x16_neon - show up when build ffmpeg 
      NDK_ARCH="arm64"
      NDK_ABIARCH="aarch64-linux-android"
      CFLAGS="${CFLAGS_} -march=armv8-a"
      LDFLAGS="${LDFLAGS_} -march=armv8-a"
      ASFLAGS=""
    ;;
    x86)
      NDK_ARCH="x86"
      NDK_ABIARCH="i686-linux-android"
      CFLAGS="${CFLAGS_} -O2 -march=i686 -mtune=intel -msse3 -mfpmath=sse -m32 -fPIC"
      LDFLAGS="-m32"
      ASFLAGS="-D__ANDROID__"
    ;;
    x86_64)
      NDK_ARCH="x86_64"
      NDK_ABIARCH="x86_64-linux-android"
      CFLAGS="${CFLAGS_} -O2 -march=x86-64 -mtune=intel -msse4.2 -mpopcnt -m64 -fPIC"
      LDFLAGS=""
      ASFLAGS="-D__ANDROID__"
    ;;
    mips)
      NDK_ARCH="mips"
      NDK_ABIARCH="mipsel-linux-android"
      CFLAGS="${CFLAGS_} -EL -march=p5600 -mhard-float"
      LDFLAGS=""
      ASFLAGS=""
    ;;
    mips64)
      NDK_ARCH="mips64"
      NDK_ABIARCH="mips64el-linux-android"
      CFLAGS="${CFLAGS_} -EL -mfp64 -mhard-float"
      LDFLAGS=""
      ASFLAGS=""
    ;;
  esac

  # cmeng: must ensure AS JNI uses the same STL library or "system"
  [[ -d ${TOOLCHAIN_PREFIX} ]] || python ${NDK}/build/tools/make_standalone_toolchain.py \
     --arch ${NDK_ARCH} \
     --api ${ANDROID_API} \
     --stl libc++ \
     --install-dir=${TOOLCHAIN_PREFIX}

  NDK_SYSROOT=${TOOLCHAIN_PREFIX}/sysroot

  # Define the install directory of the libs and include files etc
  PREFIX=${BASEDIR}/output/android/${ABI}

  # Add the standalone toolchain to the search path.
  export PATH=${TOOLCHAIN_PREFIX}/bin:$PATH
  export CROSS_PREFIX=${TOOLCHAIN_PREFIX}/bin/${NDK_ABIARCH}-
  export CFLAGS="${CFLAGS}"
  export CPPFLAGS="${CFLAGS}"
  export CXXFLAGS="${CFLAGS} -std=c++11"
  export ASFLAGS="${ASFLAGS}"
  export LDFLAGS="${LDFLAGS} -L${NDK_SYSROOT}"

  export AR="${CROSS_PREFIX}ar"
  export AS="${CROSS_PREFIX}clang"
  export CC="${CROSS_PREFIX}clang"
  export CXX="${CROSS_PREFIX}clang++"
  export LD="${CROSS_PREFIX}ld"
  export STRIP="${CROSS_PREFIX}strip"
  export RANLIB="${CROSS_PREFIX}ranlib"
  export CPP="${CROSS_PREFIX}cpp"
  export NM="${CROSS_PREFIX}nm"

  echo "**********************************************"
  echo "### Use NDK=${NDK}"
  echo "### Use ANDROID_API=${ANDROID_API}"
  echo "### Install directory: PREFIX=${PREFIX}"
  echo "**********************************************"
}
