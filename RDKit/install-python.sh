#!/bin/bash
#
# Copyright (C) 2014 Teague Sterling, Regents of University of California
#
# Usage: ./install-python Python-2.7.6.tgz /opt/python
#
# Build and install a static version of python (with dynamic libraries also)
# from a provided source tarball into a provided PYTHON_PREFIX

set -e

SOURCE_PKG="$1"
INSTALL_ROOT="$2"

INSTALL_UTILS=$( dirname $BASH_SOURCE )
LD_RUN_PATH='$ORIGIN/../lib:$ORIGIN/../local/lib'
export LD_RUN_PATH

VERSION=`basename "$SOURCE_PKG" .tgz | tr [:upper:] [:lower:]`

INSTALL_DIR="$INSTALL_ROOT/$VERSION"
ENV_DIR="$INSTALL_ROOT/envs/$VERSION"


echo "Installing Dependencies"
sudo yum -y install \
@development-tools gcc-c++ \
openssl openssl-devel openssl-static \
zlib zlib-devel zlib-static libzip libzip-devel bzip2 bzip2-devel \
db4 db4-devel \
tk tk-devel tcl tcl-devel \
freetype freetype-devel \
libpng libpng-devel libpng-static \
libffi libffi-devel \
cairo cairo-devel \
atlas atlas-sse2 atlas-sse3 atlas-devel atlas-sse2-devel atlas-sse3-devel \
blas blas-devel \
lapack lapack-devel \
suitesparse suitesparse-devel suitesparse-static \
mysql mysql-devel \
sqlite sqlite-devel \
postgresql postgresql-devel \
libevent libevent-devel

echo "Building and Installing Python (Shared)"
tar -xzf $SOURCE_PKG
cd `basename $SOURCE_PKG .tgz`
./configure --prefix=$INSTALL_DIR --enable-shared
make
make install

echo "Building and Installing Python (Static)"
./configure --prefix=$INSTALL_DIR
make
make install

#echo "Creating Local Install Resources Directory"
#mkdir -pv $INSTALL_DIR/local/lib
#( cd $INSTALL_DIR/local/lib ; ln -sv ../../lib/lib* . )

echo "Writing Bare-Bones Environmnet Script"
cat > $INSTALL_DIR/env.sh <<EOF
#!/bin/sh
export PATH="$INSTALL_DIR/bin:\$PATH"
EOF
cat > $INSTALL_DIR/env.csh <<EOF 
#!/bin/csh
setenv PATH "$INSTALL_DIR/bin:\$PATH"
EOF

if [ -f $INSTALL_UTILS/ez_setup.py ]; then
	echo "Building Packaging Tools from local scripts (Masking PATH to hide System version)"
	PATH="" $INSTALL_DIR/bin/python $INSTALL_UTILS/ez_setup.py
else
	echo "Building Packaging Tools from web (Masking PATH to hide System version)"
	wget https://bootstrap.pypa.io/ez_setup.py -O - | PATH="" $INSTALL_DIR/bin/python
fi
PATH="" $INSTALL_DIR/bin/easy_install pip

echo "Installing Important Packages"
$INSTALL_DIR/bin/pip install virtualenv
$INSTALL_DIR/bin/pip install numpy

echo "SKIPPING Useful Packages (uncomment lines below to install)"
#echo "Installing Useful Packages"
#$INSTALL_DIR/bin/pip install ipython
#$INSTALL_DIR/bin/pip install pandas
#$INSTALL_DIR/bin/pip install scipy
#$INSTALL_DIR/bin/pip install biopython
#$INSTALL_DIR/bin/pip install scikit-learn
#$INSTALL_DIR/bin/pip install psycopg2
#$INSTALL_DIR/bin/pip install MySQL-python
#$INSTALL_DIR/bin/pip install sh

echo "Installing simple web frameworks and graphics"
#$INSTALL_DIR/bin/pip install flask
$INSTALL_DIR/bin/pip install cffi
#$INSTALL_DIR/bin/pip install cairocffi

#$INSTALL_UTILS/create-virtualenv.sh $INSTALL_DIR $ENV_DIR
