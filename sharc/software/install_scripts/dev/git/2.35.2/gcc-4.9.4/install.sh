#!/bin/bash
set -eu

GIT_VERS="2.35.2"
GIT_SRC_TARBALL="git-${GIT_VERS}.tar.xz"
GIT_SRC_TARBALL_SHA256="c73d0c4fa5dcebdb2ccc293900952351cc5fb89224bb133c116305f45ae600f3"
GIT_SRC_TARBALL_URL="https://mirrors.edge.kernel.org/pub/software/scm/git/${GIT_SRC_TARBALL}"
GIT_MAN_TARBALL="git-manpages-${GIT_VERS}.tar.xz"
GIT_MAN_TARBALL_SHA256="a0e9baa54d66ac7d3648cf1f1b5af3585fcf25fa010921cb1a8d532da85d6ee8"
GIT_MAN_TARBALL_URL="https://mirrors.edge.kernel.org/pub/software/scm/git/${GIT_MAN_TARBALL}"

COMPILER="gcc"
COMPILER_VERS="4.9.4"  # system compiler

PREFIX="/usr/local/packages/dev/git/${GIT_VERS}/${COMPILER}-${COMPILER_VERS}"
MODULEFILE="/usr/local/modulefiles/dev/git/${GIT_VERS}/${COMPILER}-${COMPILER_VERS}"

# Signal handling for failure
handle_error () {
    errcode=$? # save the exit code as the first thing done in the trap function 
    echo "Error: $errcode" 
    echo "Command: $BASH_COMMAND" 
    echo "Line: ${BASH_LINENO[0]}"
    exit $errcode  # or use some other value or do return instead 
}
trap handle_error ERR

# Download and unpack src tarball
[[ -f $GIT_SRC_TARBALL ]] || wget -L $GIT_SRC_TARBALL_URL
sha256sum ${GIT_SRC_TARBALL} | grep -q $GIT_SRC_TARBALL_SHA256
if ! [[ -f .git_src_tarball_unpacked ]]; then
    tar -Jxf ${GIT_SRC_TARBALL}
    touch .git_src_tarball_unpacked
fi

# Create install and modulefile dirs
for d in $PREFIX $(dirname $MODULEFILE); do
    mkdir -m 2775 -p $d
done

# Ensure clean environment
module purge

# Build from src and install 
pushd git-${GIT_VERS}
./configure --prefix="$PREFIX"
make
make install
popd

# Download and unpack manpage tarball
[[ -f $GIT_MAN_TARBALL ]] || wget -L $GIT_MAN_TARBALL_URL
sha256sum ${GIT_MAN_TARBALL} | grep -q $GIT_MAN_TARBALL_SHA256
mkdir -m 2775 -p ${PREFIX}/man
if ! [[ -f .git_man_tarball_unpacked ]]; then
    tar -Jxf ${GIT_MAN_TARBALL} -C ${PREFIX}/man
    touch .git_man_tarball_unpacked
fi

# Set permissions and ownership
for d in $PREFIX $(dirname $MODULEFILE); do
    chmod -R g+w $d
    chgrp -R hpc_app-admins $d
done