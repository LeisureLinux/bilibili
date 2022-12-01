#### 三步创建 rpm 包
  1. 安装创建 rpm 包需要的工具
     - $ sudo dnf install -y rpmdevtools rpmlint
     - 创建需要的目录树： $ rpmdev-setuptree
  2. 写一个 spec 文件
     - 检查语法：$ rpmlint ~/rpmbuild/SPECS/mypackage.spec
  3. 创建软件包：
     - 下载源码包: $ spectool -g -R ~/rpmbuild/SPECS/mypackage.spec
     - $ rpmbuild -bb ~/rpmbuild/SPECS/mypackage.spec

---- Refer: https://linuxconfig.org/how-to-create-an-rpm-package
