## Build libvpx for iOS and Android<table>
####
<thead>
<tr><td>library</td><td>version</td><td>platform support</td><td>arch support</td><td>pull commit</td></tr>
</thead>
<tr><td>libvpx</td><td>1.7.0</td><td>ios</td><td>armv7s armv7 i386 x86_64 arm64</td><td>aae1672</td></tr>
<tr><td></td><td></td><td>android</td><td>armeabi armeabi-v7a arm64-v8a x86 x86_64 mips mips64</td><td>aae1672</td></tr>
<tr><td>curl</td><td>7.53.1</td><td>ios</td><td>armv7s armv7 i386 x86_64 arm64</td><td>aae1672</td></tr>
<tr><td></td><td></td><td>android</td><td>armeabi armeabi-v7a arm64-v8a x86 x86_64 mips mips64</td><td>aae1672</td></tr>
</table>

### Build For Android

- Use Android NDK: android-ndk-r15c
- git clone vpx-android directory into your linux working directory.
- When you first build-libvpx4android.sh, it pull the latest defined libvpx source from github.
- You may change e.g LIB_GIT="v1.7.0" to the libvpx version you want to build.
  
You build the static libvpx.a for the various architecture using the command as below.
All the built libvpx.a and *.h will be placed in the ./output/<ABI>/lib and ./output/<ABI>/include respectively

```
cd vpx-android
sh ./build-libvpx4android.sh android  # for armeabi
sh ./build-libvpx4android.sh android-armeabi #for armeabi-v7a
sh ./build-libvpx4android.sh android64-arm64 #for arm64_v8a
sh ./build-libvpx4android.sh android-x86  #for x86
sh ./build-libvpx4android.sh android64  #for x86_64
sh ./build-libvpx4android.sh android-mips  #for mips
sh ./build-libvpx4android.sh android64-mips64 #for mips64
```

Copy `lib/armeabi`, `lib/armeabi-v7a` and `lib/x86` directories to the android project
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
    
    Copyright 2014 Eng Chong Meng
        
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
       http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.




