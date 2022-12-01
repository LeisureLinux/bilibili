#### Ubuntu 支持介绍
##### Ubuntu 标准(Standard)支持
  - 4 大类组件(Components) 在支持生命周期内
    - main 和 restricted: 由 Ubuntu 安全团队提供支持 
    - unverse 和 multiverse 由 Ubuntu 社区提供支持

##### 扩展(extended) 支持
 - Ubuntu Advantage 客户可以享有额外的安全支持
 - ESM(Extended Security Maintenance) 客户可以通过 main 接收到高等级和关键 CVE 的补丁

##### -updates 和 -security 的区别
 - updates 解决 bug 
 - security 解决 updates 引入的安全漏洞

##### 组件(components)的打包策略
 - main: 只包含 main 组件
 - restricted: 包含 main 和 restricted
 - universe: 包含 main 和 universe 
 - multiverse: 包含 main, restricted, universe以及 multiverse

##### 口袋(pockets) 的打包策略
 - pocket 名称可以通过源包的 "Distribution" 入口找到
 - release: 就是简单的发行版本的名称，其他 pocket 使用 "release name"-"pocket" 形式命名, 开发版本一旦发布，就冻结不再修改
 - 在 release, security, updates 内的软件包由 Ubuntu 安全团队提供支持，backports 由社区支持
 - security: 使用 release 和 security 构建（built）
 - proposed: 使用 release, security, updates 和 proposed 构建（built）
 - updates: 该口袋内的软件包从经过测试后的 proposed 复制过来, 但是也有不经过 proposed 的情况
 - backports: 使用 release, security, updates 和 backports 构建
