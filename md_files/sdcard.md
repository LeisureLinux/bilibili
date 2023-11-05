### SD 卡简明知识

#### 两种尺寸
 - SD: 32x24x2.1 mm
 - microSD(最开始叫TF(TransFlash)卡): 11x15x1.0 mm

#### 不同 SD(Secure Digital) 卡的容量区别
 - SD: 4-2048MB
 - SDHC(High Capacity): 4-32GB，必须使用支持 SDHC 或者 SDXC 或者 SDUC 的设备
 - SDXC(eXtended Capacity): 64-2048GB，必须使用支持 SDXC 或者 SDUC 的设备
 - SDUC(Ultra Capacity): 4-128TB，必须使用支持 SDUC 的设备

 #### 读写速度
  - Rated Speed- X: 1X=150 KB/s, 600x= 90 MB/s，读的速度
  - Speed Class- C: 最小的可持续写的速度 （MB/s），分 2/4/6/10 四类
  - UHS Speed Class- U: 针对高速的 SDXC 卡，用 U 来代表速度(Ultra High Speed)，U1=10 MB/s, U3=30 MB/s
  - UHS BUS Class: 用罗马数字来表示总线速度，类似于高速公路上的车道数
  - Video Speed Class- V: 拍摄视频时的写速度， V6 到 V90 

#### 速度组合：
  - Normal 模式: C2, C4, C6
  - High Speed 模式: C2, C4, C6, C10,V6, V10
  - UHS-I 模式: C2, C4, C6, C10U1, U3V6, V10, V30 (不支持普通SD卡)
  - UHS-II & III 模式: C4, C6, C10U1, U3V6, V10, V30, V60, V90 (不支持普通SD卡)
  - SD Express 模式: E150, E300, E450, E600 (仅支持 SDXC & SDUC)

##### 举例：
  - 金士顿SDCS2 型号，指：Canvas Select Plus microSD ， UHS-I, U1, V10, A1 (32GB-128GB)/UHS-I, U3, V30, A1 (256GB-512GB)

#### 读卡器：
 - > Bus 003 Device 015: ID 05e3:0751 Genesys Logic, Inc. microSD Card Reader
 - > Bus 003 Device 014: ID 090c:6200 Silicon Motion, Inc. - Taiwan (formerly Feiya Technology Corp.) microSD card reader, Only Support SDHC
