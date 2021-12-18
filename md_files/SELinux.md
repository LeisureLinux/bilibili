#### SELinux On Ubuntu

- Remove Apparmor
  ```sh
  sudo systemctl stop apparmor
  sudo apt remove apparmor -y
  sudo reboot
  ```
- Install SELinux

  ```sh
  # sudo apt install policycoreutils selinux-utils selinux-basics -y
  sudo apt install selinux selinux-utils selinux-basics auditd audispd-plugins
  sudo selinux-activate
  sudo selinux-config-enforcing
  sudo semanage port -l|grep 'ssh'
  # If no output on above command, run below line:
  sudo semanage port -a -t ssh_port_t -p tcp 22
  sudo sestatus
  sudo reboot
  # Waiting for filesystem labeling
  sestatus
  mandb
  man -k selinux
  ```
