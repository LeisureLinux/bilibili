#### 如何在 Ububtu 上安装对应的 Debian 版本上的 Chromium 包

  1. 删除 Ubuntu 原先自带的包
      ```shell
      sudo apt remove chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg-extra
      ```
  2. 创建一个文件 /etc/apt/sources.list.d/debian.list，添加 debian buster 仓库
      ``` 
      # deb http://ftp.cn.debian.org/debian/ buster main # 中国用户
      deb [arch=amd64 signed-by=/usr/share/keyrings/debian-buster.gpg] http://deb.debian.org/debian buster main
      deb [arch=amd64 signed-by=/usr/share/keyrings/debian-buster-updates.gpg] http://deb.debian.org/debian buster-updates main
      deb [arch=amd64 signed-by=/usr/share/keyrings/debian-security-buster.gpg] http://deb.debian.org/debian-security buster/updates main
      ```
  3. 添加 Debian 签名密钥:
      ```shell
      sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DCC9EFBF77E11517
      sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
      sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 112695A0E562B32A  
      ```
  4. 保存 GPG Key 到 /usr/share/keyrings
      ```shell
      sudo apt-key export 77E11517 | sudo gpg --dearmour -o /usr/share/keyrings/debian-buster.gpg
      sudo apt-key export 22F3D138 | sudo gpg --dearmour -o /usr/share/keyrings/debian-buster-updates.gpg
      sudo apt-key export E562B32A | sudo gpg --dearmour -o /usr/share/keyrings/debian-security-buster.gpg  
      ```
  5. 配置 apt pinning ，创建 /etc/apt/preferences.d/chromium.pref 如下内容：
      ```
      # 注意: 小节之间需要空两行
      Package: *
      Pin: release a=jammy
      Pin-Priority: 500

      Package: *
      Pin: origin "*.debian.org"
      Pin-Priority: 300

      # Pattern includes 'chromium', 'chromium-browser' and similarly
      Package: chromium*
      Pin: origin "*.debian.org"
      Pin-Priority: 700 
      ```
  6. 安装 Chromium

