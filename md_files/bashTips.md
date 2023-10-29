#### 对初学者很有用的 Bash 小技巧
```
 $ npm -g install livedown
 $ echo "Hello"
```
1. 回到上次的目录：
   - cd -
   - pushd/popd
2. 清理屏幕：Ctr-L(clear), reset
3. 临时挂起进程： Ctr-z；返回： fg
4. 忘记加 sudo 命令了，怎么办？
5. 搜索命令历史
   - !102
6. 重新执行命令历史内指定的一条命令
   - !!
7. 命令历史内显示时间
   - HISTTIMEFORMAT="%m-%d %T"
   - 添加到 .bashrc
8. 终端窗口的其他快捷键：全屏，增大缩小字体
   - Ctr-Alt-t 打开终端
   - Ctr-Shift-+ 增大字体
   - Ctr-- 缩小字体
9. 命令行内跳转
   - Ctr-a 到行首
   - Ctr-e 到行尾
   - Ctr-u 删除全行
10. 用 column 命令格式化输出
    > $ mount |column -t
