#!/usr/bin/env bash
set -eu

DOWNLOAD_REQ=1

## Set these for using specific revision
SHA1_GCC=${SHA1_GCC:-HEAD}
SHA1_GDB=${SHA1_GDB:-HEAD}
SHA1_NEWLIB=${SHA1_NEWLIB:-HEAD}

TARGET=k1-elf
PREFIX=$(realpath $1)

PARALLEL_JOBS=-j6


mkdir -p $PREFIX
export PATH=$PREFIX/bin:$PATH

function git_clone() {
    local repo=$1
    local sha1=$2

    repo_dir=$(basename ${repo} ".git")
    echo "Cloning ${repo} (${repo_dir}) sha1: ${sha1}"
    if [ -d ${repo_dir} ]; then
	cd ${repo_dir}
	git fetch
	cd -
    else
	git clone --depth 1 -b coolidge ${repo}
    fi

    if [[ ! -z "${sha1}" ]]
    then
	cd ${repo_dir}
	git reset --hard ${sha1}
	cd -
    fi
}

git_clone https://github.com/kalray/gdb-binutils.git ${SHA1_GDB}
git_clone https://github.com/kalray/newlib.git ${SHA1_NEWLIB}
git_clone https://github.com/kalray/gcc.git ${SHA1_GCC}


mkdir -p build-binutils
cd build-binutils
../gdb-binutils/configure --prefix=$PREFIX --target=$TARGET --disable-initfini-array  --disable-gdb --without-gdb --disable-werror   --with-expat=yes --with-babeltrace=no --with-bugurl=no
make all $PARALLEL_JOBS
make install

cd -
cd gcc

./contrib/download_prerequisites

cd -
mkdir -p build-gcc
cd build-gcc
../gcc/configure --prefix=$PREFIX --target=$TARGET  --with-gnu-as --with-gnu-ld --disable-bootstrap --disable-shared --enable-multilib --disable-libmudflap --disable-libssp --enable-__cxa_atexit --with-bugurl=no --with-newlib                      --disable-libgomp --disable-libatomic --disable-threads --enable-languages=c --with-system-zlib

make all-gcc $PARALLEL_JOBS
make install-gcc

cd -
mkdir -p build-newlib
cd  build-newlib
../newlib/configure --target=$TARGET --prefix=$PREFIX \
            --enable-multilib \
            --enable-target-optspace \
            --enable-newlib-io-c99-formats \
            --target=${TARGET} \
	    --enable-newlib-multithread

make all $PARALLEL_JOBS
make install

cd -
cd build-gcc
make all $PARALLEL_JOBS
make install

echo "Finished"
