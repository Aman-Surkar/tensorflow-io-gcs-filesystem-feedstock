#!/bin/bash
# *****************************************************************
# (C) Copyright IBM Corp. 2021. All Rights Reserved.
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
# *****************************************************************
set -vex

PATH_VAR="$PATH"
if [[ $ppc_arch == "p10" ]]
then
    if [[ -z "${GCC_10_HOME}" ]];
    then
        echo "Please set GCC_10_HOME to the install path of gcc-toolset-10"
        exit 1
    else
        export PATH=${GCC_10_HOME}/bin/:$PATH
    fi
    GCC_USED=`which gcc`
    echo "GCC being used is ${GCC_USED}"
fi

#Clean up old bazel cache to avoid problems building TF
bazel clean --expunge
bazel shutdown

# Build Tensorflow from source
SCRIPT_DIR=$RECIPE_DIR/../buildscripts

# Pick up additional variables defined from the conda build environment
$SCRIPT_DIR/set_python_path_for_bazelrc.sh $SRC_DIR

sh ${SRC_DIR}/configure.sh

# install using pip from the whl file
bazel --bazelrc=$SRC_DIR/python_configure.bazelrc build \
      --verbose_failures $BAZEL_OPTIMIZATION //tensorflow_io_gcs_filesystem/...

python setup.py bdist_wheel --data bazel-bin --project tensorflow-io-gcs-filesystem
python -m pip install dist/*.whl

bazel clean --expunge
bazel shutdown

#Restore $PATH variable
export PATH=$PATH_VAR
