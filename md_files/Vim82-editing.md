#### Vim 8.2 手册
  0. [editing.txt 要点提炼](https://vimhelp.org/editing.txt.html)
  1. 介绍
    - 在 Vim 内编辑文件，意味着3件事情：
      - 把文件读入缓冲区
      - 修改缓冲区内容
      - 把缓冲区内容写入磁盘
    - 只要不写入文件，原始文件是不会被修改的
    - "current file name"，就是当前缓冲区，用 "%" 来代表
    - 其他文件(Alternative)，如果已经有当前文件名，可以用 "#" 来指代，用 Ctr-^ 切换
    - 多个缓冲区切换，也可以输入文件名后再按 Ctr-^ 直接切换
    - Ctr-G :file[!]，显示当前编辑的文件名，带感叹号时，显示的文件名不会截断，不管 shortmess 是否设置
    - {count}Ctr-G：显示文件的完整路径，如果 count > 1，则同时显示当前缓冲区的号码
    - gCtr-G: 显示当前位置的行/列/字/单词/字节
    - {Visual}gCtr-G: 显示可视模式时，选中的内容信息
    - :f[!]{name} : 设置当前文件名为 name 
    - :0f[!] : 删除当前缓冲区的名称
    - :buffers 或者 :files 或者 :ls 显示所有缓冲区
    - 自动保存，使用 "autowriteall" 选项

  2. 编辑
    - :edit 编辑
    - :edit[!] 丢弃缓冲区的修改，重新编辑
    - :edit {file} 如果当前缓冲区有修改则编辑失败
    - :edit! {file} 强行编辑 file，丢弃当前缓冲区修改
    - :edit#[count] 相当于 [count]Ctl-^，编辑 count 号缓冲区
    - :enew[!] 编辑新文件，! 则丢弃当前缓冲区
    - :find[!] {file} 找到 path 下的文件并编辑
    - :{count}find[!] {file} 找到 path 下匹配到第 count 个文件并编辑
    - :ex / :vi ， 两种模式切换
    - :view file， 只读查看文件
    - [count]gf 跳到光标下的文件
    - :e ++ff=unix 切换为Unix 格式，(dos),  ff 为 optionname，可以是 
        - ff=file format
        - enc=encoding or file encoding
        - bin=binary 
        - nobin= nobinary
        - bad= 特殊字符的特殊处理方式
        - edit= :read only
    - +cmd[cmd] 可以定位光标， + 表示最后一行， +{num} 表示第 num 行, +{/pat} 第一行包含 pat 的行
    - +{command} 执行 command 命令， command 是任何的 :Ex 命令

  3. 参数
    - :args 显示参数
    - :[count]argadd {name} 添加 name 到参数列表
    - :argd {pattern} 从参数列表删除 pattenr 类型的参数
    - :n 编辑下一个文件
    - :[count]N 编辑第N个前面的文件
    - :rew 编辑 arg list 里的第一个文件
    - :first 或者 :last 编辑 arg list 里的第一个或者最后一个文件
    - :wn 写入当前，编辑下一个
  4. 存盘
    - :w
    - :save
    - :wall 保存所有
  5. 保存退出
    - :q
    - :conf q
  6. 对话
    - :conf {command} 对命令 command 做确认
    - :browse {command} 对命令 command 提示文件选择对话框
  7. 当前目录
    - :cd
    - :lcd
    -
  8. 编辑二进制文件
    - 启动时，用 "-b"
  9. 加密
    - :X 提示输入加密密码
    - :set key= 可以用于设置密钥
    - :setlocal cm=zip/blowfish/blowfish2 设置加密方式
    - set cm=blowfish2 在 .vimrc 文件里 
  10. 时间戳
    - :checktime 检查文件时间戳 

  11. 文件搜索
