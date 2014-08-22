#!/bin/bash
#
# Copyright (C) 2014 Teague Sterling, Regents of University of California
# 
# Usage: ./install-rdkit.sh RDKIT_2014_03_1.tgz /opt/python
#
# This script installs RDKit and "works around" some of its
# more annoying aspects

set -e

sudo yum -y install cmake bison flex boost-devel boost-python boost-regex

RDKIT_PKG="$1"
PYTHON_PREFIX="$2"

# Determine build locations
RDKIT_VERSION=`basename $RDKIT_PKG .tgz`
RDKIT_VERSION_STORE=$PYTHON_PREFIX/opt/rdkit
RDKIT_SRC=$RDKIT_VERSION_STORE/$RDKIT_VERSION
RDKIT_BUILD=$RDKIT_SRC/build
RDBASE=$PYTHON_PREFIX/local/rdkit
export RDBASE

$PYTHON_PREFIX/bin/python -c 'import numpy' || ( echo "ERROR: Numpy is required but was not found!" && exit 1 )
$PYTHON_PREFIX/bin/python -c 'import pandas' || (echo "WARNING: Pandas not found!" && sleep 5 )


NUM_PROCS=$( grep processor /proc/cpuinfo | wc -l )
#UNCOMMENT THE FOLLOWING LINE FOR SERIAL BUILD
#NUM_PROCS=1

# Setup source tree
mkdir -pv $RDKIT_VERSION_STORE
tar -xzvf $RDKIT_PKG -C $RDKIT_VERSION_STORE
( cd $RDKIT_SRC/External/INCHI-API ; ./download-inchi.sh )

# Link current installation version to python-expected location
ln -sfnv ../opt/rdkit/$RDKIT_VERSION $RDBASE

mkdir -pv $RDKIT_BUILD
cd $RDKIT_BUILD

# Configure to use non-standard python
cmake -DPYTHON_EXECUTABLE=$PYTHON_PREFIX/bin/python \
      -DPYTHON_INCLUDE_PATH=$PYTHON_PREFIX/include/python2.7 \
      -DPYTHON_LIBRARY=$PYTHON_PREFIX/lib/libpython2.7.so \
      -DPYTHON_NUMPY_INCLUDE_PATH=$PYTHON_PREFIX/lib/python2.7/site-packages/numpy/core/include \
      -DRDK_BUILD_INCHI_SUPPORT=ON \
      -DINCHI_LIBRARY=$RDKIT_SRC/External/INCHI-API \
      -DINCHI_INCLUDE_DIR=$RDKIT_SRC/External/INCHI-API/src \
      ..

# Build with NUM_PROCS processes
make -j $NUM_PROCS
make install

# Manually install libraries to "addtional library path"
( cd $PYTHON_PREFIX/local/lib ; ln -sv ../rdkit/lib/lib* . )

# Install python path file
RDKIT_PTH=$( $PYTHON_PREFIX/bin/python -c 'import distutils;print distutils.sysconfig_get_python_lib()' )/rdkit.pth
cat > $RDKIT_PTH <<EOF
../../../local/rdkit
EOF

