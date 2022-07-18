#!/usr/bin/env bash
set -eu
unset PERL_MM_OPT

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

git_clone https://github.com/kalray/buildroot.git "${SHA1_BUILDROOT}" coolidge

cd buildroot
make O=build_kvx kvx_defconfig

# Patch config to use selected binutils, gdb, gcc, linux, uClibc-ng SHA1
sed -i -e "s/BR2_BINUTILS_VERSION=.*/BR2_BINUTILS_VERSION=${SHA1_BINUTILS}/" build_kvx/.config
sed -i -e "s/BR2_GDB_VERSION=.*/BR2_GDB_VERSION=${SHA1_GDB}/" build_kvx/.config
sed -i -e "s/BR2_GCC_VERSION=.*/BR2_GCC_VERSION=${SHA1_GCC}/" build_kvx/.config
sed -i -e "s@BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION=.*@BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION=\"\$(call github,kalray,linux_coolidge,${SHA1_LINUX})/linux-${SHA1_LINUX}.tar.gz\"@" build_kvx/.config
sed -i -e "s/BR2_UCLIBC_VERSION=.*/BR2_UCLIBC_VERSION=${SHA1_UCLIBC}/" build_kvx/.config
# need to investigate barebox

# Append to hash files
echo "sha512 ${HASH_GCC} gcc-${SHA1_GCC}.tar.gz" >> package/gcc/gcc.hash
echo "sha512 ${HASH_GDB} gdb-${SHA1_GDB}.tar.gz" >> package/gdb/gdb.hash
echo "sha512 ${HASH_BINUTILS} binutils-${SHA1_BINUTILS}.tar.gz" >> package/binutils/binutils.hash

cd build_kvx
make
