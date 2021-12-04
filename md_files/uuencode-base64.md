### 从 UUENCODE 说开来的那些事情

- uuencode

  - 来历： Unix-to-Unix Encoding
  - 被 MIME 和 yEnc 取代
  - MIME 内如果需要编码，则采用 Base64
  - 编码规则

    - 头：begin <nnn> <file> ，nnn 代表文件权限属性，例如 644。
    - 每一行的开头用 32（空格的 ASCII 十进制）+ 行长度，用对应的 ASCII 字母代表，因为除了最后一行都是 45 个字节，所以是 77 的 ASCII 码是字母 M。
    - 结尾：分为两行，一个重音符号\`，再加一个 end
    - 算法：每 3 个字节(24 位)分组，分割成 4 个 6 位的组，每组的十进制加 32 后转换成对应的 ASCII 字母。

- base64，把 3 个字节，转成 4 个 ASCII 字符

  - 头修改成： begin-base64 <nnn> <file>
  - 结尾修改成： ====
  - 中间编码后的数据只允许 [a-zA-Z0-9] 然后是 +/
  - 码表是按照 A-Z，a-z，0-9 排序的一张表，最后是 +/ ，总计 64 个字符。不满的用 = 填充
  - 算法举例：Man 的 16 进制为 0x4d, 0x61,0x6e，每 3 个一组的 8 进制变成：23 26 05 56，对应的十进制是 19 22 5 46，然后查 Base64 码表(0 为大写的 A),得到 TWFu。
  - OpenPGP：RFC4880，允许添加可选的 24 位 CRC 校验。在编码前计算，并用同样的 Base64 算法用 = 符号作为前缀分割，添加到原始的 Base64 编码输出
  - 最早采纳为标准的，现在称为 MIME Base64 的是 PEM 协议， Privacy-enhanced Electronic Mail，1987 年的 RFC989

- Percant-encoding (URL encoding)

  - 用于 URI 内的字符编码（例如中文需要转码为 ASCII 表内字符集），后来推广到 URL/URN
  - 在 Media Type 中， application/x-www-form-urlencoded，用于 HTML 表单和 HTTP 请求
  - RFC3986 2.2 节，保留字符：

    > !#$&\'()\*+,/:;=?@[] (请注意 MD 原文内星号被转义)

  - 保留字转义后的代码

    > \! %21
    > \# %23
    > \$ %24
    > \% %25
    > \& %26
    > \' %27
    > \( %28
    > \) %29
    > \- %2A \* %2B
    > \, %2C
    > \/ %2F
    > \: %3A
    > \; %3B
    > \= %3D
    > \? %3F
    > \@ %40
    > \[ %5B
    > \] %5D

  - RFC3986 2.3 节，非保留字符：[A-Za-z0-9], 然后是 hyphen, underscore, dot, tilde

- 其他的编码方式：
  - Ascii85：5 个 ASCII 编 4 个，使用在 PostScript 和 PDF，以及 git 的二进制文件补丁
    - RFC1924 版本，建议最终的 ASCII 字符包含[a-zA-Z0-9]以外，只包含 23 个，排除了 单双引号，逗号，句号，冒号，两个斜杠和中括号对，非常适合 JSON 串
    - ZMODEM 版本，4 组 8 进制组合成 5 个可打印字符
    - Adobe 版本
    - btoa 版本
- Python 代码示例

  > python3 -c "from codecs import encode;print(encode(b'Cat', 'uu'))"

- sharutils 软件包， shell archive
  - uuencode filename filename-in-encoded-file
  - sharar -C xz filenames > outputfilename
