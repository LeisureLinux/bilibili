#### [The Rustup Book](https://rust-lang.github.io/rustup/index.html)

- 概念/术语
  - channel: 发行版本的三个不同渠道： stable/beta/nightly，stable 每六周发布一次
    - 可以安装指定的版本： $ rustup toolchain install nightly-2020-07-27
    - 安装完成后检查版本： $ rustup run nightly rustc --version
    - 设置默认的版本： $ rustup default nightly
    - nightly channel 时，会缺少非默认的组件，可以用 --force 或者 --profile 来指定 rustup toolchain install 的模式
  - toolchains: Rust 的编译器，支持多种格式： channel[-\<date\>][-\<host\>], host 的方式为 target-triple
  - target triple: \<arch\>\<sub\>-\<vendor\>-\<sys\>-\<abi\>
    - arch = x86_64, i386, arm, thumb, mips ; 用 uname -m 来查看
    - sub = ARM: v5,v6m,v7a,v7m
    - vendor = pc,apple,nvidia,ibm ; Linux 系统一般都是 unknown， Windows 是 pc，MacOS 是 apple
    - sys = none,linux,win32,darwin,cuda; 用 uname -s 查看
    - abi = eabi, gnu, android, macho, el； 用 ldd --version 查看， Mac 和 BSD 没有多个 ABI，所以可以忽略
    - 全部列表： $ rustc --print target-list | pr -tw100 --columns 3
    - host 的 triple 可以用 $ rustc -Vv 的 host 字段来查看
  - component 组件: 包含必需和选项, rustup component list 查看已经安装的组件
    - 组件可以在安装 toolchain 的时候添加： $ rustup toolchain install nightly --component rust-docs
    - 也可以在安装后，手工添加： $ rustup component add rust-docs
    - 各组件解释
      - rustc - Rust 语言的编译器
      - cargo - 包管理器以及 build 工具
      - rustfmt - 代码格式化工具
      - rust-std - Rust 的标准库, 每个 target 都有不一样的标准库
      - rust-docs - 文档， 用 rustup doc 在浏览器打开文档
      - rls - 语言服务器，支持 IDE
      - clippy - lint 语法检查工具
      - miri - Rust 解释器，用来检查未定义的行为
      - rust-src - Rust 标准库的源代码，可以结合 rls，实现 IDE 的函数自动完成
      - rust-analysis - 标准库的元数据，被 rls 使用
      - rust-mingw - 构筑 x86_64-pc-windows-gnu 平台上需要的连接器以及平台库
      - llvm-tools-preview - 还处在实验阶段的 llvm 的工具集
      - rustc-dev - rust 自己的开发库，例如用于修改 clippy，一般都不需要
  - profile: 组件的逻辑分组:
    - minimal: 最少必须组件， rustc, rust-std, cargo，Windows 上建议使用本 profile
    - default: 在 minimal 之上增加了 rust-docs, rustfmt, clippy，rustup 默认使用该 profile
    - complete: 不建议使用的 profile，包含所有组件，如果确实需要添加，建议采用 $ rustup component add 来添加
    - 设置 profile: $ rustup set profile minimal
- 安装
  - 官方推荐使用 [rustup (工具链安装器)](https://github.com/rust-lang/rustup)
    - curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain stable -y
    - 安装到 ~/.cargo/bin 下，有 rustc, cargo, rustup
    - 也可以在运行 rustup-init.sh 之前，自定义 CARGO_HOME 和 RUSTUP_HOME
      - CARGO_HOME 里面是 cargo 使用到的缓冲文件，$CARGO_HOME/bin 必须包含在 PATH 环境变量里
      - RUSTUP_HOME 用来安装工具链和配置选项，是 rustup 的根
      - bash 的 rustup 自动补全： $ rustup completions bash > ~/.local/share/bash-completion/completions/rustup
      - zsh 的 rustup 自动补全： $ rustup completions zsh > ~/.zfunc/\_rustup， 然后添加 fpath+=~/.zfunc 到 .zshrc
    - Windows 下有两个 ABI： MSVC 和 GNU， rustup 默认配置 Rust 使用 MSVC ABI
      - 有 32 位和 64 位：i686-pc-windows-msvc/x86_64-pc-windows-msvc
      - 强制使用 32 位： $ rustup set default-host i686-pc-windows-msvc
      - 使用 GNU ABI： $ rustup toolchain install stable-gnu
        - 一个 toolchain 就能支持 Windows 下的四种 target，无需为了不同的 target 切换 toolchain
          - $ rustup target add x86_64-pc-windows-msvc
          - $ rustup target add x86_64-pc-windows-gnu
          - $ rustup target add i686-pc-windows-msvc
          - $ rustup target add i686-pc-windows-gnu
    - 其他安装方法是直接下载适合自己平台的 [rustup-init](https://rust-lang.github.io/rustup/installation/other.html)
    - 当然也可以自己去 [Github](https://github.com/rust-lang/rustup) 下载源码，编译一个 rustup
    - 卸载，清空： $ rustup self uninstall
- 工具链的覆盖，查看当前的 toolchain: $rustup show，去掉覆盖： $ rustup override unset
  - 快捷方式覆盖： $ cargo +beta test，使用叫做 beta 的工具链来构建
  - RUSTUP_TOOLCHAIN 环境变量覆盖
  - 目录方式覆盖 $ rustup override set 1.0.0
  - rust-toolchain.toml 文件覆盖
  - 默认 toolchain，查看或者设置默认的 toolchain: $ rustup default [nightly-2020-07027]
- 环境变量
  - RUSTUP_HOME: 默认 ~/.rustup
  - RUSTUP_TOOLCHAIN: 默认 none
  - RUSTUP_DIST_SERVER: 静态资源地址，默认 https://static.rust-lang.org， 可以设置为本地镜像
  - RUSTUP_DIST_ROOT: 已废弃，使用 RUSTUP_DIST_SERVER
  - RUSTUP_UPDATE_ROOT: 下载更新的 URL，默认： https://static.rust-lang.org/rustup
  - RUSTUP_IO_THREADS
  - RUSTUP_TRACE_DIR
  - RUSTUP_UNPACK_RAM
  - RUSTUP_NO_BACKTRACE
  - RUSTUP_PERMIT_COPY_RENAME
- rustup 配置文件: ${RUSTUP_HOME}/settings.toml，一般通过 rustup 命令行来查询和设置
- 建议把 rustup 放 ~/.cargo/bin 下，并把 ~/.cargo/bin 放到 PATH 里
  - $ 从头开始
    - $ sudo apt install rust-all (也可以看所有 librust 开头的包)
  - $ 更新
    - $ rustup update
    - $ rustup self update
  - $ rustup show 查看当前所有的已经安装的 工具链，目标
- 通过操作系统自带的 rust 软件包来编译
  - $ rustup toolchain link system /usr
  - 可以用类似：$ cargo +system build 的方法来 Build
  - 设置为默认的 toolchain ：$ rustup default system
- 针对 arm64 的编译命令
  - $ CC=aarch64-linux-gnu-gcc cargo build --target aarch64-unknown-linux-musl --release
- 针对树莓派 3 的编译命令
  - $ CC=arm-linux-gnueabihf-gcc cargo build --target arm-unknown-linux-musleabihf --release
- 针对 Windows 的编译命令
  - $ rustup target add x86_64-pc-windows-gnu
  - $ rustup toolchain install stable-x86_64-pc-windows-gnu
  - $ cargo build --target x86_64-pc-windows-gnu --release --verbose
- 用 rustc 来做交叉编译
  > $ rustc \
  >  --target=arm-unknown-linux-gnueabihf \
  >  -C linker=arm-linux-gnueabihf-gcc \
  >  hello.rs
- 用 cargo 直接创建 hello 做交叉编译
  - cargo new --bin hello
  - cd hello
  - cargo build --target=... --release
- 以下内容写入 ~/.cargo/config.toml
  > [target.arm-linux-androideabi]
  > linker = "arm-linux-androideabi-gcc"  
  > [target.armv7-unknown-linux-musleabihf]
  > linker = "arm-linux-gnueabihf-ld"  
  > [target.arm-unknown-linux-musleabihf]
  > linker = "arm-linux-gnueabihf-ld"  
  > [target.aarch64-unknown-linux-musl]
  > linker = "aarch64-linux-gnu-ld"  
  > [profile.release]
  > opt-level = 'z'
  > lto = true
  > codegen-units = 1
- [参考资料](https://rustrepo.com/repo/japaric-rust-cross-rust-embedded)
- man rustc
  - rustc --print
    > crate-name|file-names|sysroot|cfg|target-list|target-cpus|target-features
    > relocation-models|code-models|tls-models|target-spec-json|native-static-libs
