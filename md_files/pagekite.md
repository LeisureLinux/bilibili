#### --本地树莓派上的静态 http 内容映射到公网--

* 不需要备案的外网服务器上，搭建 https 服务，指向 127.0.0.1:60080
  - [B站视频：用 pagekite 透明传输，实现匿名](https://www.bilibili.com/video/BV1dM411674L/)
  - [B站视频：SSH 客户端如何通过 HTTPS 代理访问 SSH Server](https://www.bilibili.com/video/BV1rG4y1R7pa/)


```
# 本地树莓派上的隧道服务
# systemctl cat http_tunnel
# /etc/systemd/system/http_tunnel.service
[Unit]
Description="HTTP Reverse Tunnel Service"
After=network.target

[Service]
Type=simple
User=ubuntu
Restart=always
ExecStart=/usr/bin/ssh -NTC -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes  -R 60080:127.0.0.1:80 user@remote_hosted_server

[Install]
WantedBy=multi-user.target
```

---

```
  ~/.ssh/config:

Host proxy_host_name
  user = username
  ProxyCommand     nc -X connect -x proxy_host_name:443 %h %p
  ServerAliveInterval  10
```
