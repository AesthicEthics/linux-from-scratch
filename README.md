# linux-from-scratch
Building a fully customized linux system from scratch(even the kernel) to help develop a deeper understanding of what truly makes Linux tick. The goal is to cross-compile a whole linux system using a host Ubuntu system. This includes cross-compiling all libraries, basic utilities and building latest software packages from source. The goal of the project was to:

- Build and configure a Linux kernel 
- Build and install basic system tools like 'coreutils', 'binutils', and gcc
- Build and install a bootloader
- Build and a create a basic file system structure 
- Understand user management and automation using bash scripting
- Install and configure networking tools like 'dhcpd' and 'iproute2'
- and much more

The motivation behind the project was to gain a detailed understanding of the fundaemntal components that make up a linux system and how they work together

## Architecture
The foundational system toolchain was cross-compiled.

- Compiled using ubuntu 22.04 as a host on an x86_64 machine
- The parition for the LFS system was mounted on USB and all the core packages were cross-compiled from the host system to suit the target architecture. 
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
  
    The Linux kernel needs to expose an API for the systems C library to use. The linux kernel provides a set of header files for the systems C library and the other programs that need to interface with the kernel. The issue is that the header files contain very kernel specific information to be used by the kernel program itself.

    A lot of these low-level details are irrelevant to the user-space programs and may cause conflict and issues with user-space programs, thus we must run scripts that that sanitize these header files and remove kernel specific details and re-locate files in a different directory for the system C libraries to reference.
  
    ```bash
        make headers #compiles linux kernel into sanitized header files# 
        find usr/include -type f ! -name '*.h' -delete # remove all files that aren't .h (all files that arent used for compiling C/C++ code)
        cp -rv usr/include $LFS/usr # move all these files into the LFS system in the /includes folder, thats where the compilers look for headerfiles
     ```

  ### <u>Glibc</u>
  - Source: https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.1.11.tar.xz
  - Version: 6.1.11
  
    We're moving from NolibC to Glibc to provide a more functional toolchain to the new linux system. To do this, we start by creating symbolic link between the GCC  based dyanmic linking libraries on the host system and the ones we create on the target system. These allow our exectuable binaries to load shared libraries from the kernel during runtime.

    ```bash
        # check if machine is 32-bit using pattern matching (i368,i486,1586...)
        case $(uname -m) in
          i?86)
            # -f suggests if the target file already exists it should be replaced
            ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
            ;;
          x86_64)
            # two links because programs can look in either directory given x86_64
            # the names are specified in the LSB standard
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
            ;;
        esac
     ```
     
     After we configure and cross-compile glibc into our LFS system, we should see a populated ```$LFS/usr/bin```. This cross-compiles a set of system-essential tools such as ```awk```, ```ldd``` and more that are required to build software on the LFS system. 
     
     The next step for us would be modifying the ```RTLDLIST``` variable in the ```ldd``` file. ```ldd``` is a command line utility which prints the shared libraries a specific program relies on as an output and is used by many compilation and configuration scripts. The ```RTLDLIST``` variable is used by the script to determine where these shared libraries can be found and located, in our LFS system, we specify for these libraries to be located in the ```/lib``` directory as opposed to the ```/usr/lib``` dir (even though they're sym linked). 
     
     we'll use sed to remove the default-hardcoded ```/usr/lib``` path to just ```/lib``` as such:
     
     ```sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd```
     
     ### Sanity Check
     
     To make sure the newly-compiled toolchain is working as expected we write a sanity-check script to check which whether the ```$LFS``` compiler is looking for the dynamic linker in the correct locations.
     
     ```bash
      echo 'int main(){}' | $LFS_TGT-gcc -xc - # compile a simple, empty C program using the LFS gcc compiler
      readelf -l a.out | grep ld-linux # use readelf to display info about the created executable and grep for ld-linux to check for the dyanmic linker user 
      
      # expected output: [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2] (the LFS specified linker)
     ```
     
### <u>Libstdc++</u>
  - Source: https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.1.11.tar.xz
  - Version: 6.1.11
  
  C++ standard library required to compile C++ code. We didn't install this when building g++ because its installation depends on the ```Glibc``` library.

    ```bash
      ../libstdc++-v3/configure           \
          --host=$LFS_TGT                 \
          --build=$(../config.guess)      \
          --prefix=/usr                   \
          --disable-multilib              \
          --disable-nls                   \
          --disable-libstdcxx-pch         \ # we don't need pre-compiled binaries/files at the moment so we won't install them
          --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/12.2.0 # specifies installtion directory for include files. this needs to match where the the pre-installed compiler will look for include files
    ```
## Cross-Compiling System Utilities

  ### <u>M4</u>
  
   <p> M4 is a macro-processor that allows user to define macros and templates that can be used to generate text-files and configuration scripts </p>
   
   e.x. 
   
   ```m4
    # httpd.conf.m4 template

    Listen <%= $PORT %>

    DocumentRoot "<%= $DOC_ROOT %>"

    <% if ($ENABLE_SSL) { %>
    SSLEngine on
    SSLCertificateFile "<%= $CERT_FILE %>"
    <% } %>
```

  usage: 
  ```bash m4 -DPORT=8080 -DDOC_ROOT=/var/www/html -DENABLE_SSL=1 -DCERT_FILE=/path/to/cert.pem httpd.conf.m4 > httpd.conf ```
  
  ### <u>Ncurses</u>
    Ncurses is basically a frontend utility library for the terminal interface on ubuntu. This libraries provides functions that can be used to develop complex terminal interfaces with features like text formatting, mouse support, windows and etc.
    
    Before we use Ncurses, we need to install and configure ```tic```. ```tic``` is a program that allows you to compile ```terminfo``` description files that can be used by the ncurses library to control the terminal. 
    
    The terminfo files contain parameters that specify the terminal capabilities such as number of columns and rows, the colors and control sequences you can send to the sequence.
   
   Installing and configuring ```tic```:
   
   ```bash
   
        # Create a new directory called 'build'
        mkdir build

        # Change the current working directory to 'build'
        # 'pushd' will save the current directory to a stack so it can be easily returned to later
        pushd build

        # Run the configure script located in the parent directory (..)
        ../configure

        # Run the 'make' command in the 'include' directory
        # This will build any necessary files in the 'include' directory
        make -C include

        # Run the 'make' command in the 'progs' directory to build the 'tic' program
        make -C progs tic

        # Return to the original directory (the parent of 'build')
        # 'popd' will return to the directory saved on the stack earlier
        popd


   ```
   
   Cross-Compiling Ncurses:
   ```bash
     ./configure --prefix=/usr             \
              --host=$LFS_TGT              \
              --build=$(./config.guess)    \
              --mandir=/usr/share/man      \ #directory where man pages will be installed
              --with-manpage-format=normal \ # prevent installation of compressed man pages (we want normal ones lol)
              --with-shared                \ # allow ncurses to build and install shared C libraries
              --without-normal             \ # don't build static & install C libraries
              --with-cxx-shared            \ # same libary settings for C++ bindings
              --without-debug              \
              --without-ada                \ # don't build support for Ada compiler (available on host but won't be there on LFS)
              --disable-stripping          \ # don't use host tools on LFS
              --enable-widec
   ```
   
   We have to remember that the LFS system only has baby resources so we try and avoid static libraries that are directly linked to the exectuable and instead only use dynamic/shared libaries which will link to the executable on run-time and a as needed basis only saving us memory and diskspace. 
   
   After the installation steps we must run the ```bash echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so``` command to make libcurses shared library available in the ```lib``` directory so when the dynamic linker looks for it, it is available for other programs to use.
   
### <u>Bash</u>
  Literally cross compiling bash because what would we do on a linux system without one.
  
  ```bash 
    ./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc # turns off bash's memory allocation function (notorious for causing seg faults), instead it will rely on the Glibc ```malloc``` which is much better defined
  ```
  
  Remember to create a symlink for some fancy programs that use ```sh``` and not ```bash``` for the shell ```ln -sv bash $LFS/bin/sh```
  
### <u> Coreutils </u>

  This package is responsible for bringing essential system-related command-line utilities to life. This forms the basis for and introduces foundational commands like
  ```cp```, ```mkdir```, ```ls``` and more to the linux system.

  ```bash
      ./configure --prefix=/usr                     \
                --host=$LFS_TGT                   \
                --build=$(build-aux/config.guess) \
                --enable-install-program=hostname \ # enable installation of the hostname program (set and view system hostname)
                --enable-no-install-program=kill,uptime
  ```
  
  ### <u> Diffutils </u>
 
  The Diffutils package contains programs that show the differences between files or directories.
  
  ```bash
    ./configure --prefix=/usr --host=$LFS_TGT
  ```

### <u> Other Utilities </u>
  The following were also installed into the system using the same process
  - File-5.44
    - Package contains a utility to help determine the file type of given files
  - Findutils-4.9.0
    - provides the ```find``` utility that allows you to locate files in a given file system alongside maintaing search database of existing files
  - Gawk-5.2.1
    - Packages for manipulating text files
  - Grep-3.8
    - Contains utility for searching and filtering through text files
  - Gzip-1.12
    - Package responsible for compression and decompression of files
  - Make-4.4
    - Package that controls the generation of exectuables and non-source files from the source files of a package (YML file for exectuables) 
  - Patch-2.7.6
    - Contains program for modifying or creating files by applying a ```patch``` file to fix dependencies/upstream in a program
  - Sed-4.9
    - Text and file manipulation software. Contains a stream editor
  - Tar-1.34
    - Package provides the abikity to create tar archives and perform archive manipulation. 
  - Xz-5.4.1
    - Contains packages for compressing and decompressing files. Provides caapbilties for the lzma and newer compression formats. 
  
  And second passes were performe on ```Binutils-2.40``` & ```GCC-12.2.0``` to add system specific optimizations for the minimally compiled toolchain
