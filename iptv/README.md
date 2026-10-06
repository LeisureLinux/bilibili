# IPTV 播放列表（iOS / Android 通用）

纯 URL 直连、不依赖自定义请求头（iOS 端 IPTV App 普遍不支持自定义 UA），可直接在任意播放器导入。

| 文件 | 条目 | 内容 |
|---|---|---|
| [all.m3u](all.m3u) | 258 | 全量：中文 + 财经 + 英文新闻 |
| [china.m3u](china.m3u) | 205 | 中文频道专版 |
| [news.m3u](news.m3u) | 52 | 国际财经 / 英文新闻专版 |

## 订阅地址

```
https://leisurelinux.github.io/bilibili/iptv/all.m3u
https://leisurelinux.github.io/bilibili/iptv/china.m3u
https://leisurelinux.github.io/bilibili/iptv/news.m3u
```

## 说明

- 全部条目经实测可用（拉取 HLS 分片确认有真实数据）
- 已剔除依赖自定义 User-Agent 的源（iOS 播放器不支持自定义请求头）
- 列表会不定期更新，源失效属正常现象
- 本仓库只提供播放列表，不含任何频道内容

Maintained by [FreeLAMP.com](https://freelamp.com)
