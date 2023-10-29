##### 25 个 apt-get/apt-cache 包管理命令
 1. $ <u>sudo</u> apt-cache pkgnames ，列出所有可用的软件包名称
 2. $ sudo apt-cache search vsftpd，列出 vsftpd 软件包的描述 
    - $ sudo apt-cache pkgnames vsftpd 列出 vsftpd 开头的软件包
 3. $ sudo apt-cache show vsftpd 查看软件包信息
 4. $ sudo apt-cache showpkg vsftpd 查看软件包的依赖关系
 5. $ sudo apt-cache stats 查看缓冲的统计数据
 6. $ sudo apt-get update 更新系统的软件包信息
 7. $ sudo apt-get upgrade 升级软件包
    - $ apt-get dist-upgrade 解决有依赖问题的软件包（可能会删除一些软件包）
 8. $ sudo apt-get install vsftpd 安装软件包
 9. $ sudo apt-get install pkgA pkgB 同时安装多个软件包
 10. $ sudo apt-get install '*Pkg*' 安装满足通配符的软件包
 11. $ sudo apt-get install PkgName --no-upgrade 安装但是不升级
 12. $ sudo apt-get install PkdgName --only-upgrade 只升级
 13. $ sudo apt-get install vsftpd=2.3.5-3ubuntu1 只安装指定版本
 14. $ sudo apt-get remove vsftpd 删除软件包，但是不删除配置文件
 15. $ sudo apt-get purge vsftpd 完全删除软件包
 16. $ sudo apt-get clean 清理已经下载到本地的 .deb 包 
 17. $ sudo apt-get --download-only source vsftpd 下载源码包 
 18. $ sudo apt-get source vsftpd 下载并解压源码包
 19. $ sudo apt-get --compile source vsftpd 下载、解压并编译源码包
 20. $ sudo apt-get download vsftpd 下载软件包但是不安装
 21. $ sudo apt-get changelog vsftpd 查看软件包的变更日志
 22. $ sudo apt-get check 检查依赖关系是否有损坏 
 23. $ sudo apt-get build-dep vsftpd 检查依赖关系，并安装
 24. $ sudo apt-get autoclean 自动清理 /var/cache/apt/archives 下的 .deb 文件
 25. $ sudo apt-get autoremove vsftpd 自动删除因为满足依赖关系安装的软件包，但是现在已经不需要的包
