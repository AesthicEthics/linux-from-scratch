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
System toolchain was cross-c The Linux kernel needs to expose an Application Programming Interface (API) for the system's C library (Glibc in LFS) to use. This is done by way of sanitizing various C header files that are shipped in the Linux kernel source tarball. ompiled using ubuntu 22.04 as a host on an x86_64 machine. The parition for the LFS system was mounted on USB and all the core packages were cross-compiled from the host system to suit the target architecture. 

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
          --enable-langu The Linux kernel needs to expose an Application Programming Interface (API) for the system's C library (Glibc in LFS) to use. This is done by way of sanitizing various C header files that are shipped in the Linux kernel source tarball. ages=c,c++  \ # only enable C and C++ language support

      # Run the make command
      echo "[+] Running Make Command"
      make

      # Install the built software
      echo "[+] Installing Built Software"
      make install

      ```
 
  ### <u>Linux Kernel</u>
  - Source: https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.1.11.tar.xz
  - Version: 6.1.11
  
    The Linux kernel needs to expose an API for the systems C library to use. The linux kernel provides a set of header files for the systems C library and the other programs that need to interface with the kernel. The issue is that the header files contain very kernel specific information to be used by the kernel program itself.th

    A lot of these low-level details are irrelevant to the user-space programs and may cause conflict and issues with user-space programs, thus we must run scripts that that sanitize these header files and remove kernel specific details and re-locate files in a different directory for the system C libraries to reference.
  
    ```bash
        make headers #compiles linux kernel into sanitized header files# 
        find usr/include -type f ! -name '*.h' -delete # remove all files that aren't .h (all files that arent used for compiling C/C++ code)
        cp -rv usr/include $LFS/usr # move all these files into the LFS system in the /includes folder, thats where the compilers look for headerfiles
     ```
