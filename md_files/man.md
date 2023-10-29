#### 如何高效阅读 Man 手册 (mdp 版本)

***
- 根据关键字查看手册
    - $ man -aw
    - $ man -k
    - $ man -f

***
- 用浏览器查看手册
    - $ man -H
    - $ yelp "man:lsof"

***
- 用 neovim 的 Man 插件(缺省安装) 实现手册内的关键字跳转
    - $ export MANPAGER="nvim -u /dev/null +Man!"
    - 在文档里的一个文件路径上按 gf 快捷键， go to file，直接打开这个文件，用 Ctr-^ 切换
    - 在文档里的一个关键字上，如果有 man 手册，输入 :Man 可以打开这个关键字的 man 手册，按 Ctr-W O 全屏， :ls 查看 Buffer， :b <#> 切换到指定的 Buffer

***
- 查看 archlinux 网站上的手册
```
    $ alias archman='_archman() {curl -sL "https://man.archlinux.org/man/$1.raw" | man -l -}; _archman'
```
