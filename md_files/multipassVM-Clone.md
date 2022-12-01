#### 如何实现对 Ubuntu multipass 虚拟机的“克隆”
##### 因为使用了 Oh-My-Zsh 的 multipass 插件，以下 mp=multipass
  1. 用 multipass 创建一个小的虚拟机，-d 硬盘尺寸可以小一点 
    ~ ᐅ mp launch 22.04 -m 2G -c 1 -d 5g --name new-domain
  2. 获取新旧虚拟机的磁盘完整文件名(带路径)，把旧文件覆盖到新虚拟机的文件。
     ~ ᐅ sudo virsh -q domblklist orig-domain|grep vda
     ~ ᐅ sudo virsh -q domblklist new-domain|grep vda
     ~ ᐅ sudo cp orig-img-file new-img-file
  3.  重启 multipassd
     ~ ᐅ sudo snap restart multipass.multipassd 


