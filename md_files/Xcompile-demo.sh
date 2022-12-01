#!/bin/sh
# This is an Cross Compile Demo
# Use at your own risk.
# Run # apt list|egrep '^crossbuild|^mingw' to check all available crossbuild packages, then install
# Loongarch64 Buildtool 下载地址：
# https://github.com/loongson/build-tools/releases
# Loongarch64 Buildtool 解压命令：
# sudo tar xf loongarch64-clfs-20210831-cross-tools.tar.xz --strip-components=1 -C /usr

install_arm32() {
	sudo apt install gcc make gcc-arm-linux-gnueabi binutils-arm-linux-gnueabi
}

install_arm64() {
	sudo apt install gcc make gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
}

install_mingw() {
	sudo apt install mingw-w64
}

gen_hello() {
	cat >helloworld.c <<EOF
#include<stdio.h>
int main()
{
        printf("Hello World! $(date) \n");
        return 0;
    }
EOF
}

compile_x86_64() {
	gcc helloworld.c -o helloworld-x86_64
}

compile_arm32() {
	arm-linux-gnueabi-gcc helloworld.c -o helloworld-arm -static
}

compile_arm64() {
	aarch64-linux-gnu-gcc helloworld.c -o helloworld-aarch64 -static
}

compile_loongarch64() {
	loongarch64-unknown-linux-gnu-gcc helloworld.c -o helloworld-loongarch64 -static
}

compile_win64_win32() {
	x86_64-w64-mingw32-g++-win32 helloworld.c -o helloworld-win64 -static
}

compile_win64_posix() {
	x86_64-w64-mingw32-g++-posix helloworld.c -o helloworld-win64-posix -static
}

# Main.
# install_arm32
# install_arm64
export LC_ALL=C
gen_hello
compile_x86_64 || exit 1
compile_loongarch64
compile_arm32
compile_arm64
compile_win64_win32
compile_win64_posix
