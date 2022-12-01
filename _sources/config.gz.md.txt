##### /proc/config.gz 解释
- 目的：显示当前内核的编译参数
- 并非所有的发行版本都存在这个文件
  - CONFIG_IKCONFIG=y (modprobe configs)
  - CONFIG_IKCONFIG_PROC=y
- 如果以上两个参数不是（y,y）而是 (y,n) 组合，则可以用 extract-ikconfig 从内核镜像文件读取
- 对于所有的 Linux 版本，配置信息可以通过 /lib/modules/$(uname -r)/build/.config 获得
