#### 字体的故事

- 字体的分类
    - TrueType：1980 年代苹果公司开发的 Outline font standard
    - 和 Adobe 在 PostScript 里的 Type 1 fonts 竞争
    - 当年刚开发时，主流的字体
        - Times Roman
        - Helvetica
        - Courier
    - 苹果把 TrueType 免费授权给微软，后来 Adobe 宣布 Type 1 针对任何人可以开放使用 
    - 微软在 Windows 3.1 上开始采用 TrueType 字体，后来不遗余力开发了多种字体：
        - Times New Roman
        - Arial
        - Courier New
    - 微软 1994年开发了智能字体技术，命名为：TrueType Open，1996年改名为： OpenType  
    - Linux 上的 FreeType 是一个流行的字体渲染库，支持 TrueType，Type 1 以及 OpenType  
        - FreeType 支持的文件格式
            - BDF
            - PCF
            - PFR
            - PostScript
            - TrueType/OpenType
            - Windows 光栅字体 (.fon)
            - [WOFF(Web Open Font Format) (.woff/.woff2)](https://github.com/google/woff2)
                - 用于 Web 的字体
                - OpenType 或者 TrueType
                - 压缩并添加了 XML 格式元数据
                - 2009年 WOFF1 
                - 2018年 WOFF 2.0 成为 W3C 推荐
                - WOFF 2.0 引入 Brotli 压缩算法，比 1.0 能多压缩 30%
                - 绝大多数浏览器都已经支持

        - Pango：一个文本布局引擎库，用于显示多语言文本
            - 来历：2000年 GScript 和 GnomeText 项目合并成为 Pango
            - 主要用途：GTK UI 工具集的文本渲染
        - Cairo: 通用的二维向量图形渲染引擎，推荐 Pango 来渲染简单的文本

- GNU FreeFont
    - 免费的 OpenType，TrueType，WOFF 向量字体集合，但是不包含 CJK 亚洲字体
    - TypeFace
        - FreeSerif
        - FreeSans
        - FreeMono
- monospaced fonts (固定宽度)编程字体例子
   - Courier 
   - Lucida Console
   - Menlo
   - Monaco
   - Consolas
   - Inconsolata
   - Source Code Pro.
- [Serif 字体(带脚的)和 Sans-serif(不带脚) 字体](https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Serif_and_sans-serif_02.svg/418px-Serif_and_sans-serif_02.svg.png) san 在法语里的意思是“没有”, serif 的意思是“未知来源”

- 微软雅黑
    - Sans-serif 类型字体
    - 方正电子(设计师：齐立)以及 Monotype 公司
    - 微软 2004年请方正设计用于 Windows Vista
    - Windows 10 的版本引入了 Smilight, Semibold, Heavy wright 字体
    - 方正的变种字体
        - 方正兰亭黑(2006)
        - 方正兰亭刊黑(2009)
        - 方正兰亭圆(2014)
        
- 免费版权的简体中文字体
    - 宋体 类型
        - BabelStone Han
        - 文泉驿点阵宋体
    - Sans-serif 类型
        - 文泉驿正黑
        - 文泉驿微米黑
    - 其他字体
        - WenQuanYi Unibit. (monospaced)
        - AR PL UMing (Arphic Public License)
        - AR PL UKai
        - Fandol 宋体(Song)
        - Fandol 黑体(Sans-serif)
        - Fandol 楷体(Regular script)
        - Fandol 仿宋(Imitation Song)

- 主流几个字体公司
    - 常州华文
    - 方正
    - 北京汉仪

- 字体相关的网站
    - [Fontawesome](https://fontawesome.com/)
    - [Google Fonts](https://fonts.google.com/)
    - [Free Fonts](https://www.1001fonts.com/free-for-commercial-use-fonts.html)
    - [NerdFonts 古怪图标大集合](https://www.nerdfonts.com/)


- [Ubuntu 上的几种字体](https://linuxhint.com/best_fonts_ubuntu_linux/)
    - Source Code Pro
    - Hack
    - Dejavu Sans Mono
    - Fira Code
    - Roboto Mono
    - Code New Roman
    - Bitstream Vera Sans Mono
    - Open Sans
    - Inconsolata-g
    - Acme
    - Noto Mono
    - Prociono
    - Fantasque Sans Mono
    - Gugi
    - Source Sans Pro
    - IBM Plex Mono
- 常用字体
    - Sans-serif fonts: Arial Black, Arial, Comic Sans MS, Trebuchet MS, and Verdana
    - Serif fonts: Georgia and Times New Roman
    - Monospace fonts: Andale Mono and Courier New
    - Fantasy fonts: Impact and Webdings
- Linux 发行版上字体包
    - Redhat/Fedora: webcore-fonts
    - Debian：msttcorefonts
    - Ubuntu：ttf-mscorefonts-installer


