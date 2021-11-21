### XDG 基础目录

- [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/latest/ar01s03.html)

  - \$XDG_DATA_HOME 默认：$HOME/.local/share
  - \$XDG_CONFIG_HOME 默认： $HOME/.config
  - \$XDG_STATE_HOME 默认：$HOME/.local/state
  - \$XDG_DATA_DIRS 在 DATA_HOME 上的一组目录，冒号隔开，默认:/usr/local/share/:/usr/share/
  - \$XDG_CONFIG_DIRS 在 CONFIG_HOME 上的一组目录，默认：/etc/xdg
  - \$XDG_CACHE_HOME 默认： $HOME/.cache
  - \$XDG_RUNTIME_DIR 目录权限必须是 0700，login/logout 内存续

- 真实 Linux 上的例子：  
   (env|grep XDG)
  - XDG_CONFIG_DIRS=/etc/xdg/xdg-gnome-xorg:/etc/xdg
  - XDG_CURRENT_DESKTOP=GNOME
  - XDG_DATA_DIRS=/usr/share/gnome-xorg:/usr/local/share/:/usr/share/:/var/lib/snapd/desktop
  - XDG_MENU_PREFIX=gnome-
  - XDG_RUNTIME_DIR=/run/user/1000
  - XDG_SESSION_CLASS=user
  - XDG_SESSION_DESKTOP=gnome-xorg
  - XDG_SESSION_TYPE=x11
