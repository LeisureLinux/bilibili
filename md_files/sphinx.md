#### 这个网站的来历(1) -- 通过 Markdown 文件写文档
  - $ pip3 install sphinx
  - [本地 Sphinx 文档](sphinx/index.html)
  - 

```
# Configuration file for the Sphinx documentation builder.
# source/conf.py
import sphinx_rtd_theme
extensions = [
    'sphinx.ext.todo',
    'sphinxcontrib.devhelp',
    'sphinx_rtd_theme',
    'recommonmark',
]

language = 'zh'

# Exclude 掉不要处理的目录
exclude_patterns = ['.build', 'prev_md', 'Thumbs.db', '.DS_Store']


# 使用 rtd 主题
html_theme = 'sphinx_rtd_theme'
# 不显示 源文件 连接 
html_show_sourcelink = False
# 加入自己的图片，微信收款码
html_static_path = ['.static', '_my_images']
# 加入页面更新时间
html_last_updated_fmt = ' %Y-%m-%d %H:%M'

source_suffix = {
    '.rst': 'restructuredtext',
    '.md': 'markdown',
}

suppress_warnings = ['app.add_node', 'toc.excluded']

```
