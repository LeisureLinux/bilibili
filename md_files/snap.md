#### snap 介绍

  1. 查看当前版本号：  
    ```
    $ snap version
    ```

  2. 查找 snap:   
    ```
      $ snap find "$keywords"
    ```

  3. 了解 snap 信息：   
    ```
    $ snap info $snap_name
    ```

  4. 安装 snap :    
    ```
    $ sudo snap install --channel=edge/stable/beta $snap_name
    ```

  5. 连接界面管理：    
    ```
    $ snap connections $snap_name
    ```
  6. 查找所有已经安装的 snap:   
    ```
    $ snap list --all [$snap_name]; version = 开发者写的版本号， revision = snap store 分配的顺序号       
    ```
    ```
    $ snap list --all|grep disabled | awk ' {print "sudo snap remove " $1 " --revision=" $3}'|sh
    ```
  7. 更新安装的 snap:   
    ```
    $ sudo snap refresh --channel=beta $snap_name, --list/--time 查看下次 refresh 的包（时间）   
    ```
    ```
    $ sudo snap set system refresh.time=4:00-7:00,19:00-22:00
    ```   
  8. 回滚到之前的版本：    
    ```
    $ sudo snap revert $snap_name
    ```   
  9. 临时启用和禁用 snap:    
    ```
    $ sudo snap disable/enable $snap_name
    ```    
  10. 删除 snap:    
    ```
      $ sudo snap remove $snap_name [--purge]
    ```   
  11. 查看变更的具体任务：   
    ```
    $ snap changes    
    ```
    ```
    $ snap tasks $change_id
    ```
  12. Channel = <track>/<risk>/<branch>   
    ```
    track 默认为 latest, 也可以由开发者指定来写
    ```
    ```
    risk = stable/candidate/beta/edge, 以上的 channel 写法可以简写为： --channel=stable
    ```
  13. 查看/设置 snap 配置    
    ```
    $ sudo snap get/set $snap_name
    ```
  14. 查看/重启服务化的 snap    
    ```
    $ sudo snap services [$snap_name]
    ```
    ```
    $ sudo snap restart/stop/start/logs $snap_name
    ```
  15. 创建 snap 快照：   
    ```
    $ sudo snap save  
    查看快照： $ snap saved [--id=$snap_id]   
    ```
    ```
    校验： $ sudo snap check-snapshot $snap_id   
    ```
    ```
    删除快照： $ sudo snap forget $snap_id    
    ```
    ```
    导出/导入/恢复： export/import/restore    
    ```
    ```
    快照文件是一个 zip 文件，包含： meta.json; archinve.tgz(系统数据); user/<username>.tgz 用户数据   
    ```
    ```
    快照保存在 /var/lib/snapd/snapshots    
    ```
  16. snap 内部的约束： strict; classic; devmode   
  17. 启用资源(内存) quota：   
    ```
    $ sudo snap set system experimental.quota-groups=true   
    ```
    ```
    $ sudo snap set-quota highmem --memory=2GB    
    ```
    ```
    $ snap quotas
    ```
  18. 查错：   
    ```
    $ sudo systemctl restart snapd snapd.socket   
    ```
    ```
    $ snap run $snap_name    
    ```
    ```
    $ snap changes    
    ```
    ```
    $ sudo journalctl --no-pager -u snapd   
    ```
    ```
    $ sudo snap debug state /var/lib/snapd/state.json   
    ```
    ```
    $ sudo dpkg-reconfigure apparmor    
    ```
