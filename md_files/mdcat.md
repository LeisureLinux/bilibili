#### kitty+mdcat+lsd

- kitty

- mdcat

  - 安装： cargo install mdcat
  - Windows/Mac/Linux 有 Binary Release 直接下
  - 搭配的终端： iTerm2 或者 Kitty
  - 支持的 md 语法： CommonMark
  - 代码块用 syntect 高亮
  - 显示链接 🔗 和图片 🖼，能直接点击
  - svg 图片需要 rsvg-convert 支持
  - json 代码:
    ```json
        json_block = {
        [ "name": "小张",
           "语文": 100 ]
        [ "name": "小李",
           "数学": 140 ,
           "语文": 120 ]
        }
    ```
  - shell 代码:
    ```sh
        while true; do
          echo "Hello World!"
        done
        if [ $i = 2 ];then
            echo "I is 2"
        fi
    ```
