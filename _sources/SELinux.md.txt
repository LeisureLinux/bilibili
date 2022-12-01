#### SELinux On Ubuntu

- What is SELinux?
  - SELinux is a LABLELING system (Mandatory Access Controls,相比较，传统的 u/g/rwx 叫 DAC: Discretionary)
  - Every Process has a LABEL
  - Every File,Direcroty,System object has a LABEL
  - Policy rules control access between labeled processes and labeled objects
  - The Kernel enforces the rules
  - Load into /sys/fs/selinux/ , not in lsmod output
- 参考资料
  - [selinux color book](https://people.redhat.com/duffy/selinux/selinux-coloring-book_A4-Stapled.pdf)
  - [opensource.com selinux policy guide](https://opensource.com/business/13/11/selinux-policy-guide)
- Remove Apparmor
  ```sh
  sudo systemctl stop apparmor
  sudo apt remove apparmor -y
  sudo reboot
  ```
- Install SELinux

  ```sh
  sudo apt install policycoreutils selinux-utils selinux-basics auditd -y
  sudo selinux-activate
  sudo selinux-config-enforcing
  sudo semanage port -l|grep ssh
  # If no output on above command, run below line:
  sudo semanage port -a -t ssh_port_t -p tcp 22
  sudo sestatus
  sudo reboot
  # Waiting for filesystem labeling
  sestatus
  mandb
  man -k selinux
  ```

- Samples
  - Boolean
    - semanage boolean \-l
    - setsebool -p allow_ftpd_full_access ON
  - RBAC
    - semange login -a -s 'myrole' -r 's0-s0:c0.c1023' username
    - sudo -r new_role_r -i
    - ssh username/newrole_r@sshserver.com
  - Allow a service run on Non-Standard Port
    - semanage port -l
    - semanage port -a -t http_port_t -p tcp 8888
  - Infomation Gathering
    - avcstat (自从启动以来的 Access Vector Cache 统计)
    - seinfo: 不同规则的数据统计：classes, types, booleans
      - seinfo -adomain -x
      - seinfo -aunconfined_domain_type -x
      - seinfo --permissive -x
    - sesearch: 在策略里查找指定的规则
      - sesearch --role_allow -t httpd_sys_content_t
      - sesearch --allow |wc -l
      - sesearch --dontaudit |wc -l
