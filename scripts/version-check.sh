#!/bin/bash

#Script with the goal of checking version of development tools

# show the first line of the bash version from columns 2-4 using space as the delimeter
bash --version | head -n1 | cut -d" " -f2-4
# store the final aboslute path of the /bin/sh symlink to MYSH
MYSH=$(readlink -f /bin/sh)

echo "/bin/sh -> $MYSH"

#check is bash is hardset to MYSH sylink, if not, raise error
echo $MYSH | grep -q bash || echo "ERROR: /bin/sh does not point to bash"
# unset the MYSH var
unset MYSH

# -n prevents a newline character
echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
bison --version | head -n1

# check if yacc is a symbolic link
if [ -h /usr/bin/yacc ]; then
	echo "/usr/bin/yacc -> `readlink -f /usr/bin/yacc`";
# check if it is an executable
elif [ -x /usr/bin/yacc ]; then
	echo yacc is `/usr/bin/yacc --version | head -n1`
# if neither, then it doesn't exist
else
	echo "yacc not found"
fi

# chown == change owner of a file or directory
echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2

diff --version | head -n1
find --version | head -n1
gawk --version | head -n1

if [ -h /usr/bin/awk ]; then
	echo "/usr/bin/awk -> `readlink -f /usr/bin/awk`";
elif [ -x /usr/bin/awk]; then
	echo awk is `/usr/bin/awk --version | head -n1`
else
	echo "awk not found"
fi

gcc --version | head -n1
g++ --version | head -n1
grep --version | head -n1
gzip --version | head -n1
cat /proc/version
m4 --version | head -n1
make --version | head -n1
patch --version | head -n1
echo Perl `perl -V:version`
python3 --version
sed --version | head -n1
tar --version | head -n1
makeinfo --version | head -n1  # texinfo version
xz --version | head -n1

echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
if [ -x dummy ]
  then echo "g++ compilation OK";
  else echo "g++ compilation failed"; fi
rm -f dummy.c dummy
