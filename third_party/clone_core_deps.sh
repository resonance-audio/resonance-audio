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

git_clone_if_not_exist () {
  FOLDER=$1
  URL=$2
  BRANCH=$3
  if [[ ! -d "$FOLDER" ]] ; then
    git clone -b "${BRANCH}" "$URL" "$FOLDER"
  fi
}

hg_clone_if_not_exist () {
  FOLDER=$1
  URL=$2
  BRANCH=$3
  if [[ ! -d "$FOLDER" ]] ; then
    hg clone "$URL" -r "${BRANCH}" "$FOLDER"
  fi
}

cd "${SCRIPT_DIR}"
# Clone Eigen
hg_clone_if_not_exist "eigen" "https://bitbucket.org/eigen/eigen" "default"
# Clone PFFFT & apply Android patch
hg_clone_if_not_exist "pffft" "https://bitbucket.org/jpommier/pffft" "default"
if [[ -d "${SCRIPT_DIR}/pffft" ]] ; then
  cd "${SCRIPT_DIR}/pffft"
  curl https://bitbucket.org/h6a_h4i/pffft/commits/a8db21478324892d41653c9da12aed067b0caabf/raw | patch -p1
  cd "${SCRIPT_DIR}"
fi

# Install google test
git_clone_if_not_exist "googletest" "https://github.com/google/googletest.git" "master"

# Install CMake Android/iOS toolchain support (optional for Android/iOS builds)
git_clone_if_not_exist "android-cmake" "https://github.com/taka-no-me/android-cmake.git" "master"
git_clone_if_not_exist "ios-cmake" "https://github.com/leetal/ios-cmake" "master"


