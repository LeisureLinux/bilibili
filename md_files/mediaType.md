#### MIME 类型介绍
- Media Type (MIME Type)

  - 目前 IANA 是官方的标准机构定义 media type
  - 原始定义是 1996 年 11 月，RFC2045 为邮件系统定义的邮件头格式
  - 类型包含 type 和 subtype
  - 最初定义的 type：
    - [application](https://www.iana.org/assignments/media-types/application.csv)
    - [audio](https://www.iana.org/assignments/media-types/audio.csv)
    - [image](https://www.iana.org/assignments/media-types/image.csv)
    - [message](https://www.iana.org/assignments/media-types/message.csv)
    - multipart
    - [text](https://www.iana.org/assignments/media-types/text.csv)
    - [video](https://www.iana.org/assignments/media-types/video.csv))
  - 后来 type 新添加了：
    - [font](https://www.iana.org/assignments/media-types/font.csv)
    - example
    - model

- Mailcap(mail capability)，是一个元数据定义文件，定义不同的 MIME 类型的打开方式
  - 在 RFC 1524 有定义，但是不是标准
- Mime.types 把文件扩展名和 MIME 类型关联起来，然后 mailcap 把 MIME 类型和程序关联起来

- mailcap 软件包

  - compose
  - edit
  - see
  - print
  - sbin/update-mime
  - /etc/mailcap.order
  - run-mailcap == open
  - /usr/lib/mime/mailcap, /usr/lib/mime/packages/mailcap
  - mimeopen

- xdg-utils 软件包
  - xdg-mime
  - xdg-email
  - xdg-open == browse
    - gio
