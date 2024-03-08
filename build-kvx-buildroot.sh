#!/usr/bin/env bash
set -eu
unset PERL_MM_OPT

DO_GIT_ARCHIVE=$1

function git_clone() {
    local repo=$1
    local sha1=$2
    local branch=$3

    if [[ ! -z "${DO_GIT_ARCHIVE}" ]];
    then
	repo_name=${repo##*/}
	rm -rf ${repo_name}
        wget ${repo}/archive/${sha1}.zip
	unzip ${sha1}.zip
	rm ${sha1}.zip
	mv ${repo_name}-${sha1} ${repo_name}
        return
    fi

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

git_clone https://github.com/kalray/buildroot "${SHA1_BUILDROOT}" main
git_clone https://github.com/kalray/linux_coolidge "${SHA1_LINUX}" main
git_clone https://github.com/kalray/uclibc-ng "${SHA1_UCLIBC}" main
git_clone https://github.com/kalray/musl "${SHA1_MUSL}" main
git_clone https://github.com/kalray/strace "${SHA1_STRACE}" main
git_clone https://github.com/kalray/gcc "${SHA1_GCC}" main
git_clone https://github.com/kalray/binutils "${SHA1_BINUTILS}" main
git_clone https://github.com/kalray/gdb "${SHA1_GDB}" main

cd buildroot
make O=../build_buildroot_kvx kvx_defconfig
cd ../build_buildroot_kvx
cat > local.mk << EOF
LINUX_OVERRIDE_SRCDIR               := ../linux_coolidge
MUSL_OVERRIDE_SRCDIR                := ../musl
STRACE_OVERRIDE_SRCDIR              := ../strace
UCLIBC_NG_TEST_OVERRIDE_SRCDIR      := ../uclibc-ng-test
BINUTILS_OVERRIDE_SRCDIR            := ../binutils
GCC_FINAL_OVERRIDE_SRCDIR           := ../gcc
HOST_GDB_OVERRIDE_SRCDIR            := ../gdb
GCC_INITIAL_OVERRIDE_SRCDIR         := ../gcc
GDB_OVERRIDE_SRCDIR                 := ../gdb
UCLIBC_OVERRIDE_SRCDIR              := ../uclibc-ng
EOF

sed -i -e 's/BR2_TARGET_BAREBOX=y/# BR2_TARGET_BAREBOX is not set/' .config
make
