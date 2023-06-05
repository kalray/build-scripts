#!/usr/bin/env bash
set -eu

## Set these for using specific revision
SHA1_GCC=${SHA1_GCC:-HEAD}
SHA1_BINUTILS=${SHA1_BINUTILS:-HEAD}
SHA1_NEWLIB=${SHA1_NEWLIB:-HEAD}

TARGET=${TARGET:-kvx-elf}
PREFIX=$(realpath "$1")

PARALLEL_JOBS=-j6


mkdir -p "$PREFIX"
export PATH="$PREFIX/bin:$PATH"

function git_clone() {
    local repo=$1
    local sha1=$2
    local branch=$3

    if [[ "${branch}" == "-" ]];
    then
        branch=""
    else
        branch="-b ${branch}"
    fi

    repo_dir=$(basename "${repo}" ".git")
    echo "Cloning ${repo} (${repo_dir}) sha1: ${sha1}"
    if [ -d "${repo_dir}" ]; then
        (
            cd "${repo_dir}"
            git fetch
        )
    else
	      git clone ${branch} "${repo}"
    fi

    if [[ ! -z "${sha1}" ]]
    then
        (
            cd "${repo_dir}"
            git reset --hard "${sha1}"
        )
    fi
}

git_clone https://github.com/kalray/binutils.git "${SHA1_BINUTILS}" -
git_clone https://github.com/kalray/newlib.git "${SHA1_NEWLIB}" coolidge
git_clone https://github.com/kalray/gcc.git "${SHA1_GCC}" coolidge

mkdir -p build-binutils
pushd build-binutils
../binutils/configure \
    --prefix="$PREFIX" \
    --target="$TARGET" \
    --disable-initfini-array  \
    --disable-gdb \
    --without-gdb \
    --disable-werror   \
    --with-expat=yes \
    --with-babeltrace=no \
    --with-bugurl=no

make all "$PARALLEL_JOBS" > /dev/null
make install-strip
popd

pushd gcc

## This is used only when distribution does not have correct dependencies.
if [ -e /etc/os-release ] ; then
    if grep -q "CentOS Linux 7" /etc/os-release; then
        ./contrib/download_prerequisites
    fi
fi
popd

mkdir -p build-gcc
pushd build-gcc
../gcc/configure \
    --prefix="$PREFIX" \
    --target="$TARGET"  \
    --with-gnu-as \
    --with-gnu-ld \
    --disable-bootstrap \
    --disable-shared \
    --enable-multilib \
    --disable-libmudflap \
    --disable-libssp \
    --enable-__cxa_atexit \
    --with-bugurl=no \
    --with-newlib                      \
    --disable-libgomp \
    --disable-libatomic \
    --disable-threads \
    --enable-languages=c,c++ \
    --with-system-zlib

make all-gcc "$PARALLEL_JOBS" > /dev/null
make install-strip-gcc
popd

mkdir -p build-newlib
pushd build-newlib
../newlib/configure \
    --target="$TARGET" \
    --prefix="$PREFIX" \
    --enable-multilib \
    --enable-target-optspace \
    --enable-newlib-io-c99-formats \
    --enable-newlib-multithread

make all "$PARALLEL_JOBS" > /dev/null
make install
popd

pushd build-gcc
make all "$PARALLEL_JOBS" > /dev/null
make install-strip
popd

echo "Finished"

