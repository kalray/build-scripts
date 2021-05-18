#!/usr/bin/env bash
set -eu

## Set these for using specific revision
SHA1_LLVM=${SHA1_LLVM:-HEAD}

TRIPLE=kvx-kalray-cos
PREFIX=$(realpath "$1")

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

git_clone https://github.com/kalray/llvm-project "${SHA1_LLVM}" kalray/12.x/kvx-12.0.0

mkdir -p build-llvm
pushd build-llvm

cmake -G Ninja -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ \
      -DLLVM_TARGETS_TO_BUILD=KVX -DLLVM_DEFAULT_TARGET_TRIPLE=$TRIPLE \
      -DCMAKE_BUILD_TYPE=Release -DLLVM_INCLUDE_EXAMPLES=False \
      -DLLVM_PARALLEL_LINK_JOBS=2 -DLLVM_USE_LINKER=gold \
      -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -Wno-dev ../llvm-project/llvm

cmake --build . --target install
popd

echo "Finished"
