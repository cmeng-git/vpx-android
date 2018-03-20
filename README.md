## Build libvpx for Android
####
<table>
<thead>
<tr><td>library</td><td>version</td><td>platform support</td><td>arch support</td></tr>
</thead>
<tr><td>libvpx</td><td>1.7.0</td><td>android</td><td>armeabi armeabi-v7a arm64-v8a x86 x86_64 mips mips64</td></tr>
</table>

### Build For Android
- Use Android NDK: android-ndk-r15c
- git clone vpx-android directory into your linux working directory.
- When you first build-libvpx4android.sh, it pull the latest defined libvpx source from github.
- You may change e.g LIB_GIT="v1.7.0" to the libvpx version you want to build.
  
You build the static libvpx.a for the various architecture using the command as below.
All the built libvpx.a and *.h will be placed in the ./output/<ABI>/lib and ./output/<ABI>/include respectively

```
git clone https://github.com/cmeng-git/vpx-android.git ./vpx-android
cd vpx-android
export ANDROID_NDK=/opt/android/android-ndk-r15c

# setup the required libvpx
./init_libvpx.sh

# use one of the following to build libvpx
./build-libvpx4android.sh  # for all the ABI's
./build-libvpx4android.sh armeabi
./build-libvpx4android.sh armeabi-v7a
./build-libvpx4android.sh arm64_v8a
./build-libvpx4android.sh x86
./build-libvpx4android.sh x86_64
./build-libvpx4android.sh mips
./build-libvpx4android.sh mips64
```

Copy `lib/armeabi`, `lib/armeabi-v7a` and `lib/x86` etc directories to the android project
jni directory e.g. aTalk/jni/vpx

Similarly copy all the include directories to the android project jni directory.

Note: All information given below is for reference only. See aTalk/jni for its implementation.

##### ============================================
#### Android.mk makefile - for other project
Add libvpx include path to `jni/Android.mk`. 

```
#Android.mk

include $(CLEAR_VARS)
LOCAL_MODULE := libvpx
LOCAL_SRC_FILES := Your libVPX Library Path/$(TARGET_ARCH_ABI)/libvpx.a
include $(PREBUILT_STATIC_LIBRARY)

LOCAL_C_INCLUDES := $(LOCAL_PATH)/Your libvpx Include Path/libvpx
LOCAL_STATIC_LIBRARIES := libvpx
LOCAL_LDLIBS := -lz
	
```

License
-------

    ffmpeg, android static library for aTalk VoIP and Instant Messaging client
    
    Copyright 2016 Eng Chong Meng
        
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
       http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.




