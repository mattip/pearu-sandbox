#
# Prepare pytorch development environment, detect CUDA availability
#
# Usage:
#  source <this file.sh>
#
# Assumptions:
#   Existence of /usr/local/cuda-10.1.243/env.sh
#   Existence of omniscidb-cuda-dev or omniscidb-cpu-dev conda environment
#
# Author: Pearu Peterson
# Created: November 2019
#

CORES_PER_SOCKET=`lscpu | grep 'Core(s) per socket' | awk '{print $NF}'`
NUMBER_OF_SOCKETS=`lscpu | grep 'Socket(s)' | awk '{print $NF}'`
export NCORES=`echo "$CORES_PER_SOCKET * $NUMBER_OF_SOCKETS"| bc`

export CMAKE_OPTIONS="-DCMAKE_BUILD_TYPE=release -DMAPD_EDITION=EE -DMAPD_DOCS_DOWNLOAD=off -DENABLE_AWS_S3=off -DENABLE_FOLLY=off -DENABLE_JAVA_REMOTE_DEBUG=off -DENABLE_PROFILER=off -DPREFER_STATIC_LIBS=off"

if [[ -x "$(command -v nvidia-smi)" ]]
then
    # wget https://raw.githubusercontent.com/Quansight/pearu-sandbox/master/set_cuda_env.sh
    # read set_cuda_env.sh reader
    . /usr/local/cuda-10.1.243/env.sh

    # wget https://raw.githubusercontent.com/Quansight/pearu-sandbox/master/conda-envs/omniscidb-dev.yaml
    # conda env create  --file=omniscidb-dev.yaml -n omniscidb-cuda-dev
    #
    # conda env create  --file=git/Quansight/pearu-sandbox/conda-envs/omniscidb-dev.yaml -n omniscidb-cuda-dev
    #
    # conda install -y -n omniscidb-cuda-dev -c conda-forge nvcc_linux-64

    if [[ -n "$(type -t layout_conda)" ]]; then
        layout_conda omniscidb-cuda-dev
    else
        conda activate omniscidb-cuda-dev
    fi
    export CXXFLAGS="$CXXFLAGS -I$CUDA_HOME/include"
    export CPPFLAGS="$CPPFLAGS -I$CUDA_HOME/include"
    export CFLAGS="$CFLAGS -I$CUDA_HOME/include"
    export LDFLAGS="${LDFLAGS} -Wl,-rpath,${CUDA_HOME}/lib64 -Wl,-rpath-link,${CUDA_HOME}/lib64 -L${CUDA_HOME}/lib64"
    export CMAKE_OPTIONS="$CMAKE_OPTIONS -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME -DENABLE_CUDA=on"
else
    # wget https://raw.githubusercontent.com/Quansight/pearu-sandbox/master/conda-envs/omniscidb-dev.yaml
    # conda env create  --file=omniscidb-dev.yaml -n omniscidb-cpu-dev
    if [[ -n "$(type -t layout_conda)" ]]; then
        layout_conda omniscidb-cpu-dev
    else
        conda activate omniscidb-cpu-dev
    fi
    export CMAKE_OPTIONS="$CMAKE_OPTIONS -DENABLE_CUDA=off"
fi

export CONDA_BUILD_SYSROOT=$CONDA_PREFIX/$HOST/sysroot

export CXXFLAGS="`echo $CXXFLAGS | sed 's/-fPIC//'`"
export CXXFLAGS="$CXXFLAGS -DBOOST_ERROR_CODE_HEADER_ONLY"
export CXXFLAGS="$CXXFLAGS -D__STDC_FORMAT_MACROS"
export CXXFLAGS="$CXXFLAGS -Dsecure_getenv=getenv"

#export CC=$CONDA_PREFIX/bin/clang
#export CXX=$CONDA_PREFIX/bin/clang++

export CMAKE_CC=$CC
export CMAKE_CXX=$CXX

export CMAKE_OPTIONS="$CMAKE_OPTIONS -DCMAKE_C_COMPILER=$CMAKE_CC -DCMAKE_CXX_COMPILER=$CMAKE_CXX"
export CMAKE_OPTIONS="$CMAKE_OPTIONS -DCMAKE_PREFIX_PATH=$CONDA_PREFIX"
export CMAKE_OPTIONS="$CMAKE_OPTIONS -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX"
export CMAKE_OPTIONS="$CMAKE_OPTIONS -DCMAKE_SYSROOT=$CONDA_BUILD_SYSROOT"
export CMAKE_OPTIONS="$CMAKE_OPTIONS -DENABLE_TESTS=on"

# resolves `fatal error: boost/regex.hpp: No such file or directory`
echo -e "#!/bin/sh\n${CUDA_HOME}/bin/nvcc -ccbin $CC -v \$@" > $PWD/nvcc
chmod +x $PWD/nvcc
export PATH=$PWD:$PATH

test -f nvcc-boost-include-dirs.patch || wget https://raw.githubusercontent.com/conda-forge/omniscidb-cuda-feedstock/master/recipe/recipe/nvcc-boost-include-dirs.patch

echo -e "Local branches:\n"
git branch

function h () {
cat << EndOfMessage

To apply patches, run:

  patch -p1 < nvcc-boost-include-dirs.patch

To configure, run:

  mkdir -p build && cd build

  cmake -Wno-dev \$CMAKE_OPTIONS ..

To build, run:

  make -j $NCORES

To test, run:

  mkdir tmp && bin/initdb tmp
  make sanity_tests

To serve, run:

  mkdir data && bin/initdb data
  bin/omnisci_server --enable-runtime-udf --enable-table-functions

EndOfMessage

}

h