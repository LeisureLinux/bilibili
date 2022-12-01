#### 如何高效阅读 Man 手册
 1. 根据关键字查看手册
    - $ man -aw
    - $ man -k
    - $ man -f
 2. 用浏览器查看手册
    - $ man -H
    - $ yelp "man:lsof"
 3. 用 neovim 的 Man 插件(缺省安装) 实现手册内的关键字跳转
    - $ export MANPAGER="nvim -u /dev/null +Man!"
 4. 查看 archlinux 网站上的手册
    - alias archman='_archman() {curl -sL "https://man.archlinux.org/man/$1.raw" | man -l -}; _archman'
