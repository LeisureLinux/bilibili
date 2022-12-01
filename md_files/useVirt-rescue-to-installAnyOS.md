#### 使用 virt-rescue 在不丢数据的情况下，改变成任意的操作系统
 - From Ubuntu to Debian
 - From Debain to Fedora
   - download Fedora cloud image
   - virt-rescue -a debian.img -a fedora.img
   - mount fedora root, chroot
   - In fedora root, mount debian OS to /mnt
   - yum install --overwrite --root=/mnt
