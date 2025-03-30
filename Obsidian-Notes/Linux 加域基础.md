---
share: true
---

#### Linux 加域基础
- 安装软件包：`$ sudo apt install -y sssd sssd-tools adcli libnss-sss libpam-sss realmd packagekit krb5-user`
- 执行加域：`$ sudo realm join --user=domain-user-name leisurelinux.com`
- 验证：
	- `$ sudo sssctl domain-list`
	- `$ sudo realm list`
- 更新 PAM： `sudo pam-auth-update`
- 配置 sssd.conf，重启 sssd
```
[sssd]
domains = leisurelinux.com
config_file_version = 2
services = nss, pam, ifp, sudo

[domain/leisurelinux.com]
id_provider = ad
access_provider = ad
sudo_provider = ad
get_domains_timeout = 10
default_shell = /bin/bash
krb5_store_password_if_offline = true
cache_credentials = true
krb5_realm = LEISURELINUX.COM
ad_domain = leisurelinux.com
realmd_tags = manages-system joined-with-adcli 
fallback_homedir = /home/adhome/%u
use_fully_qualified_names = false 
```

- 配置 krb5.conf：
```
[libdefaults]
	default_realm = LEISURELINUX.COM
	dns_lookup_realm = true
	dns_lookup_kdc = true
    rdns = false
	renew_lifetime = 1d
	kdc_timesync = 1
	ccache_type = 4
	forwardable = true
	proxiable = true

[realms]
	LEISURELINUX.COM = {
		kdc = ds-demo01.leisurelinux.com
		master_kdc = ds-demo01.leisurelinux.com
		admin_server = ds-demo01.leisurelinux.com
		default_domain = leisurelinux.com
	}

[domain_realm]
	.leisurelinux.com = LEISURELINUX.COM
	leisurelinux.com = LEISURELINUX.COM

[logging]
  default = FILE:/var/log/krb5libs.log
  kdc= FILE:/var/log/krb5kdc.log
  admin_server = FILE:/var/log/kadmind.log
```
- 配置 ~/.ssh/config：添加：`GSSAPIDelegateCredentials yes`
- 配置 /etc/ssh/sshd_config，重启 sshd
```
KerberosAuthentication yes
KerberosOrLocalPasswd yes
KerberosTicketCleanup yes
GSSAPIAuthentication yes
GSSAPICleanupCredentials yes
GSSAPIStrictAcceptorCheck yes
```
- 配置 sudo：添加： `"%domain admins" ALL=(ALL) ALL`

#视频教程： https://www.bilibili.com/video/BV1ptZcYdEcC/

#Kerberos 
