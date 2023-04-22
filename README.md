# linux-from-scratch
Building a fully customized linux system from scratch to help develop a deeper understanding of what truly makes Linux tick. The goal is to cross-compile a whole linux system using a host Ubuntu system. This includes cross-compiling all libraries, basic utilities and building latest software packages from source. The goal of the project was to:

- Build and configude a Linux kernel 
- Build and install basica system tools like 'coreutils', 'binutils', and gcc
- Build and install a bootloader
- Build and a create a basic file system structure 
- Understand user management and automation using bash scripting
- Install and configure networking tools like 'dhcpd' and 'iproute2'
- and much more

The motivation behind the project was to gain a deailted understanding of the fundaemntal components that make up a linux system and how they work together

## Architecture
System toolchain was cross-compiled using ubuntu 22.04 as a host on an x86_64 machine. The parition for the LFS system was mounted on USB and all the core packages were cross-compiled from the host system to suit the target architecture. 

- Filesystem: ext4

## Cross-Compiled ToolChain
### <u>BinUtils</u>
  - Source: https://sourceware.org/pub/binutils/releases/binutils-2.40.tar.xz
  - Version: 2.40
    ```bash
        ../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror
      ```
      
  ### <u>GCC</u>
  - Source: https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz
  - Version: 12.2.0
    ```bash
      #!/bin/bash

      # Run the configure script with the specified options
      ../configure                  \
          --target=$LFS_TGT         \ # set the target system for the compiler
          --prefix=$LFS/tools       \ # set the installation directory
          --with-glibc-version=2.37 \ # specify the version of glibc
          --with-sysroot=$LFS       \ # set the root environment for the build
          --with-newlib             \ # use NewLib as the base C library
          --without-headers         \ # do not compile with system headers
          --enable-default-pie      \ # enable position independent executables
          --enable-default-ssp      \ # enable stack smashing protection
          --disable-nls             \ # disable multilingual support
          --disable-shared          \ # do not generate dynamic libraries
          --disable-multilib        \ # disable building multiple target libraries
          --disable-threads         \ # disable multithreading
          --disable-libatomic       \ # disable atomic operations
          --disable-libgomp         \ # disable OpenMP
          --disable-libquadmath     \ # disable Quadmath
          --disable-libssp          \ # disable SSP
          --disable-libvtv          \ # disable VTV
          --disable-libstdcxx       \ # disable libstdc++
          --enable-languages=c,c++  \ # only enable C and C++ language support

      # Run the make command
      echo "[+] Running Make Command"
      make

      # Install the built software
      echo "[+] Installing Built Software"
      make install

      ```
 
