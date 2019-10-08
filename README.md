# Welcome to OS porting guide

This guide should give you some information about porting newlib and gcc to make new OS aware toolchain.

## How to build existing elf (bare) toolchain

Kalray provides source codes of gdb/binutils, gcc and newlib that contain our port of Kalray's MPPA Coolidge core.

To build this toolchain, you have to clone this repository that contains build script and references of others repositories for each Kalray's deliveries.
Theses references correspond to official Kalray's deliveries.
For example: You will get references sha1 of gcc, gdb/binutils and newlib for official code drop 5 in file 4.0.0-cd5.refs.

To build elf toolchain for this code drop 5:

```
source ./4.0.0-cd5.refs
./build-scripts/build-k1-xgcc.sh <prefix>
```
Prefix is the path where toolchain will be installed.

