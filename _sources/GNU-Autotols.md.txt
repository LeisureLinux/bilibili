##### GNU Auto Tools

- History
- Books
- References
  1. [Introduction to GNU Autotools](https://opensource.com/article/19/7/introduction-gnu-autotools)
  2. [GNU Autoconf, Automake and Libtool Slides](https://www.shlomifish.org/lecture/Autotools/slides--all-in-one-html/)
  3. [Escape from GNU Autohell!](https://www.shlomifish.org/open-source/anti/autohell/)
- 相比于 CMake ，Autotools 的缺点
  1. 使用 m4 和 /bin/sh，很容易造成语法问题，CMake 则是用 C++ 写的
  2. 很费时，特别是在 cygwin 上，运行 autoreconf 或者 ./autogen.sh
  3. 用 CMake 很快，而 libtool 动辄上千行的 shell 脚本，很笨重
  4. autotool 打包后的文件比 CMake 大很多
  5. GNU Autohell 最大的问题是前后兼容性问题，需要持续维护，而 CMake 则在向后兼容性上做得非常好
  6. CMake 对 Win32 的支持非常好
  7. CMake 使用修改后的 BSD 许可，而无需遵循 Autotools 的严格的 GPL 协议
  8. CMake 容易上手
- Autotools 的“三板斧”
  1. ./configure ，扫描当前运行系统，用于发现默认设置，各种软件和库的位置
  2. make, 根据自动生成的 Makefile ，把源代码“翻译”为机器语言
  3. make install，把 make 结果生成的“二进制”文件以及其他相关文档，配置等，复制到指定的目录下
- Autotools 的优点 (GCC = the GNU Compiler Collection)
  1. 可移植性
  2. 自动根据操作系统类型打包
- 如何使用
  - 核心组件
    - automake 包： automake & aclocal，aclocal 根据 configure.in 和 acinclude.m4 生成 aclocal.m4；automake 根据 Makefile.am 文件生成 Makefile.in 文件
    - autoconf 包： autoconf, autoheader, autom4te, autoreconf, autoscan, autoupdate, ifnames； autoconf 根据 configure.in (2.5 版本后为 configure.ac)，生成 ./configure 脚本；autoheader 根据 acconfig.h 文件生成 config.h.in 模板。
    - make 包： make
  - 目录结构
    - src: 源代码
      - NEWS
      - README
      - AUTHORS
      - ChangeLog
    - configure.ac ， autoconf 使用该文件生成 configure 脚本，必须至少包含如下前面两个 m4 宏
      - AC_INIT ，格式：软件包名称，版本，Email 地址，项目 URL，源.tar 的名称
      - AC_OUTPUT, 可以不带任何附加参数
      - AM_INIT_AUTOMAKE, 用来生成 Makefile，不带任何参数
      - AC_CONFIG_FILES, 参数：输出文件的文件名称
      - 指定编译器，如果是 C 则是 AC_PROG_CC，如果是 C++，则是 AC_PROG_CXX
      - AM_PROG_LIBTOOL，这个宏用来指定编译 library，即 libtool 工具
    - Makefile.am
      - \_PROGRAMS 结尾的变量，需要编译的源代码
      - \_SCRIPTS 结尾的变量，需要包含的脚本
      - \_DATA 结尾的变量，需要包含的数据文件
      - \_LIBRARIES 结尾的变量，需要编译的库
      - bin_PROGRAMS，用这个变量来指定最终生成的二进制文件的名称，后续的其他变量都可以用这个名称作为前缀
      - bin_SCRIPTS，如果最终的目标不需要编译，则可以用这个变量来指定目标需要放置的路径，例如 bin/myscript
      - AUTOMAKE_OPTIONS = foreign subdir-objects，automake 默认读取 src 目录下的文件，如果需要读取另外的目录用 foreign 变量
    - ./configure 运行后，通过 Makfile.in 以及其他文件，生成 Makefile
    - autoreconf --install 生成 configure 脚本，以及其他辅助脚本
    - make dist: 生成 .tar.gz 的源代码文件包含 autotool 相关的文件，用户可以自己去编译
