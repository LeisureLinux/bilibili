### 修改 markmap-cli 为本地路径渲染 [适用于不能上公网的场景]

##### <div style="text-align: right"> @github/LeisureLinux  [ver 0.1.2.20211113] </div>  
- 如果 markmap 或者 markmap-cli 不能在命令行下运行，添加一个软连接  
        ```
         $ ln -s ~/node_modules/markmap-cli/bin/cli.js ~/.local/bin/markmap  
        ```
- 安装 markmap-toolbar 到本地  
        ```
          $ npm install markmap-toolbar
        ```
- 如果是在 vim-coc 插件下，需要修改的 node_modules 路径是：  
        ``` 
         ~/.config/coc/extensions/node_modules/coc-markmap/node_modules
        ``` 
- $ vim ~/node_modules/markmap-lib/dist/index.js  
    - 原先的代码：  
        ```
        const BASE_JS = [`https://cdn.jsdelivr.net/npm/d3@${"6.6.0"}`, `https://cdn.jsdelivr.net/npm/markmap-view@${"0.2.6"}`]
        ```
    - 修改为：  
        ```
        const path = require("path");
        var path_nm = path.relative(
          path.basename(__dirname) + '/../',
          require("os").homedir() + '/node_modules'
        );
        const BASE_JS = [ path_nm + `/d3/dist/d3.js`,  path_nm + `/markmap-view/dist/index.js`].map(src => ({
        ```
- $ vim ~/node_modules/markmap-cli/dist/index.js
    - 原先的代码：  
        ```
        const TOOLBAR_VERSION = "0.1.6";
        const TOOLBAR_CSS = `npm/markmap-toolbar@${TOOLBAR_VERSION}/dist/style.min.css`;
        const TOOLBAR_JS = `npm/markmap-toolbar@${TOOLBAR_VERSION}/dist/index.umd.min.js`;
        const SITE=`https://cdn.jsdelivr.net/`;
        ```
    - 修改为：  
        ```
            const path = require("path");
            var path_nm = path.relative(
              path.basename(__dirname) + '/../',
              require("os").homedir() + '/node_modules'
            );
            const TOOLBAR_CSS = `style.min.css`;
            const TOOLBAR_JS = `index.umd.min.js`;
            const SITE = path_nm + `/markmap-view/node_modules/markmap-toolbar/dist/`;
        ```

