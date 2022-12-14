#### 如何压缩 PDF 文件
  - 很简单：Github 上有一个 [shrinkpdf.sh](https://github.com/aklomp/shrinkpdf) 的脚本，用 Ghostscript 压缩 PDF 到 72dpi
  - ./shrinkpdf.sh -g -r 90 -o out.pdf in.pdf
    - g: 彩色变灰色
    - r: dpi 分辨率，默认 72dpi


