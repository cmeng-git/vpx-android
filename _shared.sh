#!/bin/bash

unset ANDROID_API
unset CROSS_COMPILE
# export ANDROID_NDK="/opt/android/android-ndk-r15c" - last working is r15c without errors
# r16b => Unable to invoke compiler: /opt/android/android-ndk-r16b/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-gcc but build?

BASEDIR=`pwd`

# Never mix two api level to build static library for use on the same apk.
# Set to API:15 for aTalk minimun support for platform API-15
# Does not build 64-bit arch if ANDROID_API is less than 21 - the minimum supported API level for 64-bit.
ANDROID_API=21
NDK_ABI_VERSION=4.9

# Do not change naming convention of the ABIS; see:
# https://developer.android.com/ndk/guides/abis.html#Native code in app packages
# Android recomended architecture support; others are deprecated
# ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
ABIS=("armeabi" "armeabi-v7a" "arm64-v8a" "x86" "x86_64" "mips" "mips64")

NDK=${ANDROID_NDK}
HOST_NUM_CORES=$(nproc)
# Do not modify any of the NDK_ARCH, CPU and -march unless you are sure.
# The settings are used by <ARCH>-linux-android-gcc and submodule configure
# https://en.wikipedia.org/wiki/List_of_ARM_microarchitectures
# $NDK/toolchains/llvm/prebuilt/...../includellvm/ARMTargetParser.def etc
# ARCH - should be one from $ANDROID_NDK/platforms/android-$API/arch-* [arm / arm64 / mips / mips64 / x86 / x86_64]"


configure() {
  ABI=$1;
  TOOLCHAIN_PREFIX=${BASEDIR}/${ABI}-android-toolchain

  case $ABI in
    armeabi)
      # Deprecated in r16. Will be removed in r17
      NDK_ARCH="arm"
      export ARCH_FLAGS="-mthumb -finline-limit=64"
      export ARCH_LINK=""
      export NDK_ABIARCH="arm-linux-androideabi"
      export ASFLAGS=""
    ;;
    armeabi-v7a)
      NDK_ARCH="arm"
      export ARCH_FLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -mthumb -mfpu=neon"
      export ARCH_LINK="-march=armv7-a -Wl,--fix-cortex-a8"
      export NDK_ABIARCH="arm-linux-androideabi"
      export ASFLAGS=""
    ;;
    arm64-v8a)
      # Valid cpu = armv8-a cortex-a35, cortex-a53, cortec-a57 etc. but -march=armv8-a is required
      # x264 build has own undefined references e.g. x264_8_pixel_sad_16x16_neon - show up when build ffmpeg 
      NDK_ARCH="arm64"
      export ARCH_FLAGS="-march=armv8-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -mfpu=neon"
      export ARCH_LINK=""
      export NDK_ABIARCH="aarch64-linux-android"
      export ASFLAGS=""
    ;;
    x86)
      NDK_ARCH="x86"
      export ARCH_FLAGS="-O2 -march=i686 -mtune=intel -msse3 -mfpmath=sse -m32"
      export ARCH_LINK=""
      export NDK_ABIARCH="i686-linux-android"
      export ASFLAGS="-D__ANDROID__"
    ;;
    x86_64)
      NDK_ARCH="x86_64"
      export ARCH_FLAGS="-O2 -march=x86-64 -msse4.2 -mpopcnt -m64 -mtune=intel"
      export ARCH_LINK=""
      export NDK_ABIARCH="x86_64-linux-android"
      export ASFLAGS="-D__ANDROID__"
    ;;
    mips)
      NDK_ARCH="mips"
      export ARCH_FLAGS=""
      export ARCH_LINK=""
      export NDK_ABIARCH="mipsel-linux-android"
      export ASFLAGS=""
    ;;
    mips64)
      NDK_ARCH="mips64"
      export ARCH_FLAGS=""
      export ARCH_LINK=""
      export NDK_ABIARCH="mips64el-linux-android"
      export ASFLAGS=""
    ;;
  esac

  # cmeng: must ensure AS JNI uses the same STL library or "system"
  [ -d ${TOOLCHAIN_PREFIX} ] || python $NDK/build/tools/make_standalone_toolchain.py \
     --arch ${NDK_ARCH} \
     --api ${ANDROID_API} \
     --stl libc++ \
     --install-dir=${TOOLCHAIN_PREFIX}

  SYSROOT=${TOOLCHAIN_PREFIX}/sysroot
  # export TOOLCHAIN_PATH=${TOOLCHAIN_PREFIX}/bin
  PREFIX=${BASEDIR}/output/android/${ABI}

  export PATH=$TOOLCHAIN_PREFIX/bin:$PATH
  export CROSS_PREFIX=${TOOLCHAIN_PREFIX}/bin/${NDK_ABIARCH}-
  export CC=${CROSS_PREFIX}clang
  export CXX=${CROSS_PREFIX}clang++
  export LINK=${CXX}
  export LD=${CROSS_PREFIX}ld
  export AR=${CROSS_PREFIX}ar
  export RANLIB=${CROSS_PREFIX}ranlib
  export STRIP=${CROSS_PREFIX}strip
  export LIBS=${LIBS:-""}
  export CFLAGS="${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing"
  export CXXFLAGS="${CFLAGS} -std=c++11 -frtti -fexceptions"
  export LDFLAGS="${ARCH_LINK}"

  echo "**********************************************"
  echo "use ANDROID_API=${ANDROID_API}"
  echo "use NDK=${NDK}"
  echo "export ABIS=${ABIS}"
  echo "export CROSS_PREFIX=${CROSS_PREFIX}"
  # echo "export SYSROOT=${SYSROOT}"
  echo "export CC=${CC}"
  echo "export CXX=${CXX}"
  echo "export LINK=${LINK}"
  echo "export LD=${LD}"
  echo "export AR=${AR}"
  echo "export RANLIB=${RANLIB}"
  echo "export STRIP=${STRIP}"
  # echo "export CPPFLAGS=${CPPFLAGS}"
  echo "export CFLAGS=${CFLAGS}"
  echo "export CXXFLAGS=${CXXFLAGS}"
  echo "export LDFLAGS=${LDFLAGS}"
  echo "export LIBS=${LIBS}"
  echo "export ASFLAGS=${ASFLAGS}"
  echo "**********************************************"
}
