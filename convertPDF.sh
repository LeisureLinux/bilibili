#!/bin/sh
# 批量转换 PDF 文件添加水印
# Github & Bilibili ID: LeisureLinux
# 1. 转换 jpg 格式的水印图片为 PDF
#   $ convert watermark.jpg watermark.pdf
#   convert 命令来自 ImageMagic 软件包
#   如果报错需要修改 policy 文件如下：
#   $ sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml
# 2. 用 Gnumeric 软件包随带的 ssconvert 命令，可以批量把 Excel 转换为 PDF
#   例如： $ ssconvert all_obes_orders.xlsx -S all_obes_%s.pdf
# 3. 添加水印背景到现有的 PDF 文件，输出为 output.pdf
#   qpdf 命令来自 qpdf 软件包
producer="Leisure-Linux"
src_pdf="IBM-Cross-Compile.pdf"
output="output.pdf"
rm $output 2>/dev/null
wm_pdf="watermark.pdf"
qpdf --underlay $wm_pdf --repeat=1 -- \
	--encrypt '' $(sha256sum $src_pdf | cut -d ' ' -f1) 128 \
	--print=none --extract=n --modify=none --use-aes=y --cleartext-metadata -- \
	$src_pdf $output
# 4. 添加 Producer 元数据
# exiftool 命令来自 exiftool 软件包
exiftool -Producer=$producer -overwrite_original $output
# 5. To verify you can run:
pdfinfo $output
