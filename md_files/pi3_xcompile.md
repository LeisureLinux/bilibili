#### 树莓派3，即 armv6 的交叉编译
  - 交叉编译的概念：
    - build platform: 用于构建的平台，例如在 x86_64 上构建
    - host platform: 构建目标的平台架构 ，例如 树莓派 armv6
    - target platform: 需要处理编译完的二进制的平台架构，简单讲就是和开发工具有关
    - 三元组：架构-厂商-操作系统，例如：arm-linux-gnueabihf- (运行 gcc -dumpmachine)

  - armv6 的问题：
    - Ubuntu 或者 Debian 自带的包： gcc-arm-linux-gnueabihf 或者 crossbuild-essential-armhf 
      里面的 /usr/bin/arm-linux-gnueabihf-gcc -v 显示 --with-arch=armv7-a ，不支持 armv6
    - 解决办法： git clone https://github.com/raspberrypi/tools.git; 把 arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64 目录软连接到一个短一点的路径，例如 /opt/armv6，设置其下面的 bin 目录为 PATH 第一条，即 PATH=/opt/armv6/bin:$PATH，再执行 xxx-gcc -v 会显示 --with-arch-armv6，这个就是最核心的要素，导致之前编译完成后报 illegal instructions

  - 编译 openssl
    - 了解完以上核心问题后，再重新来编译 openssl，就简单了。

```
     $ apt source openssl
     $ cd openssl-1.xxx
     $ ./Configure linux-generic32 shared -marm -march=armv6 -mfpu=vfp -mfloat-abi=hard --prefix=/opt/build/openssl --openssldir=/opt/build/openssl/openssl --cross-compile-prefix=arm-linux-gnueabihf-
     $ make
     $ make install_sw ，不安装 man 手册
```
     
  - 编译 expat
```
     $ apt source expat
     $ cd expat-xxx
     $ ./configure --host=arm-linux-gnueabihf --target=arm-linux-gnueabihf --prefix=/opt/build/expat 
     $ make && make install 
```

  - 编译 unbound
```
     $ 去 github 下载最新版的 unbound-latest.tar.gz，解开后 cd unbound-1.17.0
     $ ./configure --host=arm-linux-gnueabihf --target=arm-linux-gnueabihf  --prefix=/opt/build/unbound --with-ssl=/opt/build/openssl --with-libexpat=/opt/build/expat
     $ make ARCH=armv6 && make install
```
  - 最后把 build 下的三个目录分别 rsync 到树莓派的 /usr/local 下（注意千万不要写到 /usr 下）
  - /etc/ld.so.conf 里确保 /usr/local/lib 在里面，修改后运行 sudo ldconfig 

