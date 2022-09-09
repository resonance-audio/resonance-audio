#!/bin/bash
# Copyright 2018 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Change working directory to script folder
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd "${SCRIPT_DIR}"


PROFILE="Release"
VERBOSE_MAKE=""

declare -a BUILD_FLAGS
declare -a CONFIG_FLAGS

ANDROID_NDK="$ANDROID_SDK_ROOT/ndk/21.3.6528147/"
ANDROID_NATIVE_API_LEVEL="21"
ANDROID_ABI="armeabi-v7a with NEON"
ANDROID_SELECT_ENABLED=0
case "$(uname -s)" in
  Linux*) ANDROID_TOOLCHAIN_HOST="linux-x86_64";;
  CYGWIN*|MINGW*|MSYS*) ANDROID_TOOLCHAIN_HOST="windows-x86_64"
esac

MSVC_GENERATOR="Visual Studio 14 2015 Win64"

function show_help()
{
  cat <<EOF
*** Resonance Audio compilation script ***

Please select a build target:

  -t= | --target=[RESONANCE_AUDIO_API|         # Resonance Audio API C/C++ library
                  RESONANCE_AUDIO_TESTS|       # Resonance Audio unit tests
                  GEOMETRICAL_ACOUSTICS_TESTS| # Geometrical Acoustics unit tests
                  UNITY_PLUGIN|                # Resonance Audio Unity plugin
                  WWISE_AUTHORING_PLUGIN|      # Resonance Audio Wwise authoring plugin
                  WWISE_SOUND_ENGINE_PLUGIN|   # Resonance Audio Wwise sound engine plugin
                  FMOD_PLUGIN|                 # Resonance Audio FMOD plugin
                  VST_MONITOR_PLUGIN]          # Resonance Audio VST monitor plugin

  -p= | --profile=[Debug|Release], default: Release

  --verbose_make             # Enables verbose make/build output.
  --android_toolchain |      # Use Android NDK toolchain (may need adjustments to ANDROID_NDK,
  --android_toolchain=[ABI]  # ANDROID_NATIVE_API_LEVEL, ANDROID_ABI script variables).
                             # ABI options=[armeabi-v7a|arm64-v8a|x86|x86_64]
  --ios_os_toolchain         # Use iOS ARM toolchain.
  --ios_simulator_toolchain  # Use iOS X86 simulator toolchain.
  --msvc_dynamic_runtime     # Enables dynamic runtime environment linking in MSVC builds.
  --msvc_x86                 # Build Windows x86 32 bit
EOF
exit
}

BUILD_TARGET=""

for i in "$@"
do
  case $i in
    -p=*|--profile=*)
      PROFILE="${i#*=}"
      shift # past argument=value
      ;;

    -t=*|--target=*)
      BUILD_TARGET="${i#*=}"
      shift # past argument=value
      ;;

    --verbose_make)
      CONFIG_FLAGS+=(-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON)
      shift # past argument with no value
      ;;

    --android_toolchain=*)
      ANDROID_ABI="${i#*=}"
      if [ $ANDROID_ABI == "armv7-a" ]
      then
        CONFIG_FLAGS+=(-DANDROID_ABI="armeabi-v7a with NEON")
      else
        CONFIG_FLAGS+=(-DANDROID_ABI="${ANDROID_ABI}")
      fi
      ANDROID_SELECT_ENABLED=1
      CONFIG_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake)
      CONFIG_FLAGS+=(-DANDROID_NDK="${ANDROID_NDK}")
      CONFIG_FLAGS+=(-DANDROID_NATIVE_API_LEVEL="${ANDROID_NATIVE_API_LEVEL}")
      CONFIG_FLAGS+=(-DCMAKE_ANDROID_API_MIN="${ANDROID_NATIVE_API_LEVEL}")
      CONFIG_FLAGS+=(-DANDROID_STL="c++_shared")
      CONFIG_FLAGS+=(-DANDROID_STL_FORCE_FEATURES="OFF")
      CONFIG_FLAGS+=(-DANDROID_ARM_MODE="arm")
      CONFIG_FLAGS+=(-DCMAKE_MAKE_PROGRAM=$ANDROID_SDK_ROOT/cmake/3.18.1/bin/ninja)
      CONFIG_FLAGS+=(-DCMAKE_STRIP=${ANDROID_NDK}/toolchains/llvm/prebuilt/$ANDROID_TOOLCHAIN_HOST/bin/llvm-strip)
      shift # past argument with no value
      ;;

    --android_toolchain)
      ANDROID_SELECT_ENABLED=1
      CONFIG_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake)
      CONFIG_FLAGS+=(-DANDROID_NDK="${ANDROID_NDK}")
      CONFIG_FLAGS+=(-DANDROID_NATIVE_API_LEVEL="${ANDROID_NATIVE_API_LEVEL}")
      CONFIG_FLAGS+=(-DCMAKE_ANDROID_API_MIN="${ANDROID_NATIVE_API_LEVEL}")
      CONFIG_FLAGS+=(-DANDROID_ABI="${ANDROID_ABI}")
      CONFIG_FLAGS+=(-DANDROID_STL="c++_shared")
      CONFIG_FLAGS+=(-DANDROID_STL_FORCE_FEATURES="OFF")
      CONFIG_FLAGS+=(-DANDROID_ARM_MODE="arm")
      CONFIG_FLAGS+=(-DCMAKE_MAKE_PROGRAM=$ANDROID_SDK_ROOT/cmake/3.18.1/bin/ninja)
      shift # past argument with no value
      ;;

    --ios_os_toolchain)
      CONFIG_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=./third_party/ios-cmake/ios.toolchain.cmake)
      CONFIG_FLAGS+=(-DPLATFORM=OS)
      CONFIG_FLAGS+=(-DDEPLOYMENT_TARGET=9.0)
      shift # past argument with no value
      ;;

    --ios_simulator_toolchain)
      CONFIG_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=./third_party/ios-cmake/ios.toolchain.cmake)
      CONFIG_FLAGS+=(-DPLATFORM=SIMULATOR64)
      CONFIG_FLAGS+=(-DDEPLOYMENT_TARGET=9.0)
      shift # past argument with no value
      ;;

    --msvc_dynamic_runtime)
      CONFIG_FLAGS+=(-DSTATIC_MSVC_RUNTIME:BOOL=OFF)
      shift # past argument with no value
      ;;

    --msvc_x86)
      MSVC_GENERATOR="Visual Studio 14 2015"
      shift # past argument with no value
      ;;

    *)
      # unknown option
      echo "Unknown option: ${i}"
      show_help
      ;;
  esac
done

[[ -z "$BUILD_TARGET" ]] && show_help

# Number of CPU cores/parallel compilation instances (for Darwin/Linux builds)
NUM_CORES=8

# Create build environment.
rm -fr build && mkdir build && cd build

case "$(uname -s)" in
  Darwin)
    BUILD_FLAGS+=(-j "${NUM_CORES}")
    cmake -DBUILD_"${BUILD_TARGET}":BOOL=ON\
      -DCMAKE_BUILD_TYPE=Release\
      "${CONFIG_FLAGS[@]}" "$@" ..
    ;;

  Linux)
    if [ $ANDROID_SELECT_ENABLED == 0 ]
    then
      BUILD_FLAGS+=(-j "${NUM_CORES}")
      cmake -DBUILD_"${BUILD_TARGET}":BOOL=ON\
        "${CONFIG_FLAGS[@]}" "$@" ..
    else
      cmake -G"Ninja"\
        -DBUILD_"${BUILD_TARGET}":BOOL=ON\
        -DCMAKE_BUILD_TYPE=Release\
        "${CONFIG_FLAGS[@]}" "$@" ..
    fi
    ;;

  CYGWIN*|MINGW*|MSYS*)
    if [ $ANDROID_SELECT_ENABLED == 0 ]
    then
      cmake -G"${MSVC_GENERATOR}"\
        -DBUILD_"${BUILD_TARGET}":BOOL=ON\
        "${CONFIG_FLAGS[@]}" "$@" ..
    else
      cmake -G"Ninja"\
        -DBUILD_"${BUILD_TARGET}":BOOL=ON\
        -DCMAKE_BUILD_TYPE=Release\
        "${CONFIG_FLAGS[@]}" "$@" ..
    fi
    ;;

  *)
    ;;
esac

INSTALL_TARGET="install"
if echo "${BUILD_TARGET}" | grep -q "TESTS"; then
  INSTALL_TARGET=""
fi

cmake --build . --config "${PROFILE}" --target "${INSTALL_TARGET}" -- "${BUILD_FLAGS[@]}"
