[![Build Status](https://travis-ci.com/kalray/build-scripts.svg?branch=master)](https://travis-ci.com/kalray/build-scripts)

# Welcome to OS porting guide

This guide should give you some information about porting newlib, binutils and gcc to make new OS aware toolchain.

## How to build existing elf (bare) toolchain

Kalray provides source codes of binutils, gcc and newlib that contain our port of Kalray's MPPA Coolidge core.

To build this toolchain, you have to clone github repository  https://github.com/kalray/build-scripts that contains build script and references of others needed repositories.
These references correspond to official Kalray's deliveries.
They are located in refs/ directory and named "4.0.0-cd9.refs", "4.0.0-cd10.refs", etc...
The file "last.refs" in the top directory points to the latest Kalray delivery.

For example: You will get SHA1 references of GCC, binutils and newlib for last official code drop in file last.refs.

To build elf toolchain for this version:

```bash
source ./last.refs
./build-scripts/build-kvx-xgcc.sh <prefix>
```
Prefix is the path where toolchain will be installed.

## Elf toolchain

What is provided in Elf toolchain?
- gcc compiler able to support C/C++ languages
- binutils for assembler, linker and disassembler
- libc: newlib with minimal boot support

This toolchain can be used to build simple bare code. It supports some magic syscalls to support printf for example. This toolchain is the basis for OS porting. There is no OS provided and so no thread or any OS functionality supported.

## OS porting

There is several kind of Operating Systems:
- Single System Control Loop
- Multi-Tasking Operating System
- Rate Monotonic Operating System
- Preemptive Operating System

Lib C is not always mandatory. It depends on application needs.
Elf toolchain provides libc as example of boot code and magic syscall support.
It can be used to port OS specific libc.

### GNU binary utilities (binutils)

This component is necessary to generate binaries but should not be modified for OS porting.
You have only to modify the config.sub in case of unkown OS.
Example with FreeRTOS:

```diff
git diff
diff --git a/config.sub b/config.sub
index 5a728e8..bc919fa 100755
--- a/config.sub
+++ b/config.sub
@@ -1400,7 +1400,7 @@ case $os in
              | -os2* | -vos* | -palmos* | -uclinux* | -nucleus* \
              | -morphos* | -superux* | -rtmk* | -rtmk-nova* | -windiss* \
              | -powermax* | -dnix* | -nx6 | -nx7 | -sei* | -dragonfly* \
-              | -cos* | -mbr* \
+              | -cos* | -mbr* | -freertos* \
              | -skyos* | -haiku* | -rdos* | -toppers* | -drops* | -es* \
              | -onefs* | -tirtos*)
        # Remember, each alternative MUST END IN *, to match a version number.
```

### GCC

https://github.com/kalray/gcc

To make OS specific toolchain, it is possible to modify gcc driver to get kvx-<os>-gcc. This driver will be able to link specific OS librairies for example.
First of all, GCC internal documentation can be found here: https://gcc.gnu.org/onlinedocs/gccint

KVX is the Kalray's processor family name. Main KVX specific targetting files are here:

```
gcc/config/kvx/
```
It targets several toolchain versions:
- elf
- mbr (MPPA Bare Runtime) used internally
- cos (ClusterOS)
- linux

Files that configure gcc's driver for elf toolchain:
- kvx-elf.h
- kvx.opt
- t-elf
- t-kvx

These files are used in gcc/config.gcc:

```bash
kvx-*-elf*)
	tm_file="${tm_file} elfos.h dbxelf.h kvx/kvx-elf.h newlib-stdint.h"
	tmake_file="kvx/t-kvx kvx/t-elf"
	;;
```

Example of targetting for FreeRTOS:
- add your OS in config.sub if not yet supported in gcc. Example with FreeRTOS:
```diff
git diff ./config.sub
diff --git a/config.sub b/config.sub
index 7fabc3d..70595a5 100755
--- a/config.sub
+++ b/config.sub
@@ -1411,7 +1411,7 @@ case $os in
              | -morphos* | -superux* | -rtmk* | -rtmk-nova* | -windiss* \
              | -powermax* | -dnix* | -nx6 | -nx7 | -sei* | -dragonfly* \
              | -skyos* | -haiku* | -rdos* | -toppers* | -drops* | -es* \
-             | -onefs* | -tirtos* | -phoenix* | -fuchsia* | -redox* | -cos* | -mbr*)
+             | -onefs* | -tirtos* | -phoenix* | -fuchsia* | -redox* | -cos* | -mbr* | -freertos*)
        # Remember, each alternative MUST END IN *, to match a version number.
                ;;
        -qnx*)
```
- create kvx-freertos.h from kvx-elf.h. For FreeRTOS:
```c
cat gcc/config/kvx/kvx-freertos.h
/* Machine description for KVX MPPA architecture family.
   Copyright (C) 2020 Kalray Inc.

   This file is part of GCC.

   GCC is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3, or (at your option)
   any later version.

   GCC is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with GCC; see the file COPYING3.  If not see
   <http://www.gnu.org/licenses/>.  */

#ifndef GCC_KVX_MPPA_FREERTOS
#define GCC_KVX_MPPA_FREERTOS

#define STARTFILE_SPEC " crti%O%s crtbegin%O%s crt0%O%s"
#define ENDFILE_SPEC " crtend%O%s crtn%O%s"

#define DRIVER_SELF_SPECS DRIVER_SELF_SPECS_COMMON

/* Link against Newlib libraries, because FreeRTOS need is.
   This part can be modified for OS porting and other libc.
   Handle the circular dependence between libc and libgloss.
   Link against MPPA Bare Runtime
 */
#undef  LIB_SPEC
#define LIB_SPEC "--start-group -lc -lgloss --end-group " \
  "%{!nostartfiles:%{!nodefaultlibs:%{!nostdlib:%{!T*:-Tbare.ld}}}}"

#undef LINK_SPEC
#define LINK_SPEC \
  LINK_SPEC_COMMON

#endif /* GCC_KVX_MPPA_FREERTOS */
```

- create t-freertos from t-elf. Example for FreeRTOS:
```
cat ./gcc/config/kvx/t-freertos
MULTILIB_OPTIONS = fno-exceptions
MULTILIB_DIRNAMES = noexceptions
```
- add configuration line in gcc/config.gcc for freeRTOS:
```bash
kvx-*-freertos*)
	tm_file="${tm_file} elfos.h dbxelf.h kvx/kvx-freertos.h newlib-stdint.h"
	tmake_file="kvx/t-kvx kvx/t-freertos"
	;;
```

### Newlib (libc)

Equivalent to board support package of Newlib is in newlib/libgloss/kvx-elf for Elf toolchain.
It contains support for:
- boot: start.S, boot_c.c, boot_args.c, crt0.c, crti.c and crtn.c
- bsp: bsp.c, exceptions.c exceptions_pl0.c, handlers.c, syscall.c, context.c and diagnostic.c
- system: access.c, chdir.c, chmod.c, close.c, dup.c, dup2.c, exit.c, fcntl.c, fstat.c, getpagesize.c, gettimeofday.c, isatty.c, link.c, lseek.c, mkdir.c, open.c, read.c, rmdir.c, sbrk.c, stat.c, unlink.c, write.c, asm_syscalls.c, mkfifo.c, nanosleep.c, times.c, sleep.c and usleep.c

Basic startup point for FreeRTOS port is:
- Modify newlib/config.sub to add FreeRTOS:
```diff
git diff ./config.sub
diff --git a/config.sub b/config.sub
index 7c526fb..54ab48d 100755
--- a/config.sub
+++ b/config.sub
@@ -1401,7 +1401,7 @@ case $os in
              | -morphos* | -superux* | -rtmk* | -rtmk-nova* | -windiss* \
              | -powermax* | -dnix* | -nx6 | -nx7 | -sei* | -dragonfly* \
              | -skyos* | -haiku* | -rdos* | -toppers* | -drops* | -es* | -mbr* \
-             | -onefs* | -tirtos* | -phoenix* | -cos*)
+             | -onefs* | -tirtos* | -phoenix* | -cos* | -freertos* )
        # Remember, each alternative MUST END IN *, to match a version number.
                ;;
        -qnx*)
```
- FreeRTOS libgloss:
 - copy all libgloss/kvx-elf directory to libgloss/kvx-freertos
 - Defines kvx-freertos in libgloss/configure.in:

```diff
git diff ./configure.in
diff --git a/libgloss/configure.in b/libgloss/configure.in
index 61eda97..13df055 100644
--- a/libgloss/configure.in
+++ b/libgloss/configure.in
@@ -126,6 +126,10 @@ case "${target}" in
        AC_CONFIG_SUBDIRS([kvx-cos])
        config_libnosys=false
        ;;
+  kvx*-*-freertos)
+       AC_CONFIG_SUBDIRS([kvx-freertos])
+       config_libnosys=false
+       ;;
   lm32*-*-*)
        AC_CONFIG_SUBDIRS([lm32])
        ;;
```
 - Execute 2.69 autoconf in libgloss directory

**At this point you should be able to build a FreeRTOS toolchain**

## Boot sequence

RM core in each cluster is normally dedicated to firmware: management of L2 cache, hypervisor, etc...
So boot is done on RM to initialize cluster memory mapped registers for L2 cache, APIC, GIC and MAILBOX.

**RM boot sequence**:
- start.S: `_start`: core 64 bits mode, setting of the stack pointer and call of `__kvx_rm_c_startup`
- boot_c.c: `__kvx_rm_c_startup`: 
```c
void __kvx_rm_c_startup(void)
{
  __kvx_low_level_startup();
  __kvx_rm_init();
  __kvx_do_rm_startup();
  __kvx_stop();
}
```
- boot_c.c: `__kvx_low_level_startup`
  - init of exception vector (SFR:EV)
  - enable icache, dcache, streaming load, hardware loop
  - init of interupts, DAME (Data Asynchronous Memory Error)
  - init of memory mapped registers for L2 cache, APIC, GIC and MAILBOX
  - enable L1 cache coherency
  - init of power controller

- boot_c.c: `__kvx_rm_init`
  - TLS and BSS sections init

- boot_c.c: `__kvx_do_rm_startup`
  - call of `__kvx_start_pe(PE0, __kvx_pe_libc_start, __kvx_libc_args, KVX_PE_STACK_START)`

- boot_c.c: `__kvx_start_pe`
  - init of `_KVX_PE_START_ADDRESS`: address of startup routine to call at boot time
  - init of `_KVX_PE_ARGS_ADDRESS`: address of `kvx_boot_args_t` structure to pass `argc`, `argv` and `envp`
  - init of `_KVX_PE_STACK_ADDRESS`: PE0 stack start address
  - wakeup PE0 using power controller

- boot_c.c: `__kvx_stop`
  - set RM in IDLE mode

**PE0 boot sequence**:

- start.S: `_start`: core 64 bits mode, setting of the stack pointer and call of `__kvx_pe_libc_start` previously given during RM boot.

- boot_c.c: `__kvx_pe_c_startup`: 
```c
void __kvx_pe_c_startup(void)
{
  __kvx_low_level_startup();
  __kvx_do_pe_startup();
  __kvx_stop();
}
```
- boot_c.c: `__kvx_low_level_startup`
  - init of exception vector (SFR:EV)
  - enable icache, dcache, streaming load, hardware loop
  - init of interupts, DAME (Data Asynchronous Memory Error)
  - enable L1 cache coherency
  - init of power controller

- boot_c.c: `__kvx_do_pe_startup`
  - `__kvx_pe_init`: init of sections TLS and BSS
  - `__kvx_finish_newlib_init`: some libc internal init for reentrance
  - register `__kvx_newlib_flushall` at exit to flush mainly IO streams at exit.
  - call main routine
  - call exit
  - while(1)

- boot_c.c: `__kvx_do_rm_startup`
  - call of `__kvx_start_pe(PE0, __kvx_pe_libc_start, __kvx_libc_args, KVX_PE_STACK_START)`

- boot_c.c: `__kvx_start_pe`
  - init of `_KVX_PE_START_ADDRESS`: address of startup routine to call at boot time
  - init of `_KVX_PE_ARGS_ADDRESS`: address of kvx_boot_args_t structure to pass argc, argv and envp
  - init of `_KVX_PE_STACK_ADDRESS`: PE0 stack start address
  - wakeup PE0 using power controller

- boot_c.c: `__kvx_stop`
  - set RM in IDLE mode

## Exceptions handling

KVX cores have an Exception Vector register to initialize with a vector of 4 trampolines of maximum size 0x40 bytes:
- DEBUG
- TRAP
- INTERRUPT
- SYSCALL

At boot time, `SFR[EV]` is initialized to `KVX_EXCEPTION_ADDRESS` initialized by default in bare.ld linker script:

```c
KVX_EXCEPTION_ADDRESS = DEFINED(KVX_EXCEPTION_ADDRESS) ? KVX_EXCEPTION_ADDRESS : 0x400;
KVX_DEBUG_ADDRESS     = KVX_EXCEPTION_ADDRESS + 0x00;
KVX_TRAP_ADDRESS      = KVX_EXCEPTION_ADDRESS + 0x40;
KVX_INTERRUPT_ADDRESS = KVX_EXCEPTION_ADDRESS + 0x80;
KVX_SYSCALL_ADDRESS   = KVX_EXCEPTION_ADDRESS + 0xc0;
```
Each address is used to init specific sections address in bare.ld linker script:

```c
  .exception.debug KVX_DEBUG_ADDRESS : {
    /* The debug exception handler */
    KEEP(*(.exception.debug))
  } > internal_mem

  .exception.trap KVX_TRAP_ADDRESS : {
    /* The debug exception handler */
    KEEP(*(.exception.trap))
  } > internal_mem

  .exception.interrupt KVX_INTERRUPT_ADDRESS : {
    /* The debug exception handler */
    KEEP(*(.exception.interrupt))
  } > internal_mem

  .exception.syscall KVX_SYSCALL_ADDRESS : {
    /* The debug exception handler */
    KEEP(*(.exception.syscall))
  } > internal_mem
  . = ALIGN(0x40);
```

All exception trampolines are defined in start.S:

```
	.section .exception.debug, "ax", @progbits
	.globl kv3_debug_handler_trampoline
	.proc kv3_debug_handler_trampoline
kv3_debug_handler_trampoline:
	goto __kvx_asm_exceptions_handler
	;;
	.endp kv3_debug_handler_trampoline

	.section .exception.trap, "ax", @progbits
	.globl kv3_trap_handler_trampoline
	.proc kv3_trap_handler_trampoline
kv3_trap_handler_trampoline:
	goto __kvx_asm_exceptions_handler
	;;
	.endp kv3_trap_handler_trampoline

	.section .exception.interrupt, "ax", @progbits
	.globl kv3_interrupt_handler_trampoline 
	.proc kv3_interrupt_handler_trampoline
kv3_interrupt_handler_trampoline:
	goto __kvx_asm_exceptions_handler
	;;
	.endp kv3_interrupt_handler_trampoline

	.section .exception.syscall, "ax", @progbits ;\
	.globl kv3_syscall_handler_trampoline ;\
	.proc kv3_syscall_handler_trampoline
kv3_syscall_handler_trampoline:
	goto __kvx_asm_exceptions_handler
	;;
	.endp kv3_syscall_handler_trampoline
```

- exceptions.S: `__kvx_asm_exceptions_handler`
  - Save context
  - Call corresponding exception handler depending on SFR[EC] (Exception Cause)
  - Each exception handler call corresponding `__kvx_do_<exception type>`
  - Restore context

- handlers.c: `__kvx_do_hwtrap`
  - if write is defined, print error message and exit with 1 as error code
  - cluster power off

- handlers.c: `__kvx_do_interrupt`
  - if `__kvx_int_handlers[<it number>]` is registered, call it

- handlers.c: `__kvx_do_interrupt_dame`
  - Do the same thing than `__kvx_do_hwtrap`

- handlers.c: `__kvx_do_debug`
  - Do the same thing than `__kvx_do_hwtrap`

- handlers.c: `__kvx_do_scall`
  - syscall numbers are defined in libgloss/kvx-elf/include/kv3/scall_no.h
  - only syscalls write and exit are managed.
  - syscall write (17) uses magic syscall 4094
  - syscall exit (1) uses magic syscall 4095.

## Lock handling

OS must provides some lock interface that must be used by libc.
For elf toolchain, locks are defined in ./newlib/libc/sys/kvx/lock.c.
As example, ClusterOS provides its locks api used in ./newlib/libc/sys/cos/lock.c.
