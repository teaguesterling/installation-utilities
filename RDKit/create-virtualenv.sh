#!/bin/sh

# Make RDKit and Virtualenv play nice

# TODO: This should be converted to virtualenv wrapper

STANDALONE=""
if [ $1 == '-s' ]; then
	STANDALONE="yes"
	shift
fi

SOURCE_DIR=$1
ENV_DIR=$2

shift

echo "Creating Virtualenv $ENV_DIR"
#echo "$SOURCE_DIR/bin/virtualenv --system-site-packages $ENV_DIR"
# Use system site packages to fix numpy build issues
$SOURCE_DIR/bin/virtualenv --system-site-packages "$@"

echo "Patching virtualenv scripts"
if [ ! -z "$STANDALONE" ]; then
	mkdir -pv $ENV_DIR/local/lib
else
	ln -sv $SOURCE_DIR/local $ENV_DIR/local
fi

LIB_PATH=$( ls $SOURCE_DIR/lib/libpython*.so.* )
LINK_PATH=$( ls $SOURCE_DIR/lib/libpython*.so )
LIB_NAME=$( basename $LIB_PATH)
LINK_NAME=$( basename $LINK_PATH )
cp -v $SOURCE_DIR/lib/libpython*.so.* $ENV_DIR/lib
cp -v $SOURCE_DIR/lib/libpython*.a $ENV_DIR/lib
( cd ${ENV_DIR}/lib ; ln -sv $LIB_NAME $LINK_NAME )

sed "s|$SOURCE_DIR|$ENV_DIR|g" $SOURCE_DIR/bin/pydoc > $ENV_DIR/bin/pydoc
sed "s|$SOURCE_DIR|$ENV_DIR|g" $SOURCE_DIR/bin/smtpd.py > $ENV_DIR/bin/smtpd.py
sed "s|$SOURCE_DIR|$ENV_DIR|g" $SOURCE_DIR/bin/idle > $ENV_DIR/bin/idle
sed "s|$SOURCE_DIR|$ENV_DIR|g" $SOURCE_DIR/bin/2to3 > $ENV_DIR/bin/2to3
sed "s|$SOURCE_DIR|$ENV_DIR|g" $SOURCE_DIR/bin/python-config > $ENV_DIR/bin/python-config
chmod -v +x $ENV_DIR/bin/pydoc $ENV_DIR/bin/smtpd.py $ENV_DIR/bin/idle $ENV_DIR/bin/2to3

echo "Entering Virtualenv"
source $ENV_DIR/bin/activate

echo "Reinstalling packages with executables"
# The following packages have executable scripts that must be (re)installed 
# in the virtualenv
pip install --upgrade --force-reinstall virtualenv
pip install --upgrade --force-reinstall nose
pip install --upgrade --force-reinstall numpy

echo "Installing additional packages"
pip install ipython

echo "Writing env activate scripts"

cat > $ENV_DIR/env.sh <<EOF
VIRTUAL_ENV=\$( dirname \$BASH_SOURCE )
if [ -z \$VIRTUAL_ENV_DISABLE_PROMPT ]; then 
	VIRTUAL_ENV_DISABLE_PROMPT=yes
	CLEAR_VIRTUAL_ENV_DISABLE_PROMPT=yes
fi
export VIRTUAL_ENV_DISABLE_PROMPT
source \$VIRTUAL_ENV/bin/activate
if [ ! -z \$CLEAR_VIRTUAL_ENV_DISABLE_PROMPT ]; then
	unset VIRTUAL_ENV_DISABLE_PROMPT
fi
EOF
echo "set VIRTUALENV=$ENV_DIR" > $ENV_DIR/env.csh
cat >> $ENV_DIR/env.csh <<EOF
if( ! (\$?VIRTUAL_ENV_DISABLE_PROMPT) ) then 
	set VIRTUAL_ENV_DISABLE_PROMPT=yes
endif
source \$VIRTUAL_ENV/bin/activate.csh
if( (\$?VIRTUAL_ENV_DISABLE_PROMPT) && \$?_OLD_VIRTUAL_PROMPT != 0 ) then
	set prompt="\$_OLD_VIRTUAL_PROMPT" 
	unset VIRTUAL_ENV_DISABLE_PROMPT
	unset _OLD_VIRTUAL_PROMPT
endif
EOF

deactivate

if [ ! -z $STANDALONE ]; then
	echo "Detaching from parent build"
	$SOURCE_DIR/bin/virtualenv "$@"
else
	if [ -e $SOURCE_DIR/lib/python2.7/site-packages/rdkit.pth ]; then
		cp -v $SOURCE_DIR/lib/python2.7/site-packages/rdkit.pth $ENV_DIR/lib/python2.7/site-packages/rdkit.pth
	fi
	PIP_TMP=$( mktemp )
	$SOURCE_DIR/bin/pip freeze > $PIP_TMP
        $ENV_DIR/bin/pip install -r $PIP_TMP
	rm -v $PIP_TMP
fi
