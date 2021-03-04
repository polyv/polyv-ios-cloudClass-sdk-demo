#### ❗️ 该项目已废弃不再维护，请移步至：[保利威多场景项目](https://github.com/polyv/polyv-ios-livescenes-sdk-demo)
---
# polyv-ios-cloudClass-sdk-demo

[![build passing](https://img.shields.io/badge/build-passing-brightgreen.svg)](#)
[![GitHub release](https://img.shields.io/badge/release-v0.16.3-blue.svg)](https://github.com/polyv/polyv-ios-cloudClass-sdk-demo)
[![GitHub release](https://img.shields.io/badge/维护状态-废弃-red.svg)](https://github.com/polyv/polyv-ios-livescenes-sdk-demo)

本项目从属于广州易方信息科技股份有限公司旗下的POLYV保利威视频云核心产品“云课堂”，是一款云课堂教学的示例 APP。该 demo 包含了视频教学直播、ppt 在线演示同步播放、教学连麦、在线聊天功能，以及直播回放功能。非常适合直播视频教学的应用场景。想要集成本项目提供的 SDK，需要在[保利威视频云平台](http://www.polyv.net/)注册账号，并开通相关服务。

保利威云课堂涵盖十分众多的功能，业务较复杂。考虑到不同客户的需求，我们的代码分为以下两部份提供：

- 云课堂观看 SDK：客户不可修改的底层的基本功能； 
- Demo 开源代码：支持客户二次开发/修改的 UI、交互、聊天室、公告栏、答题卡等扩展功能。

因而我们推荐的集成方式，是在使用 Demo 中的开源代码的基础上进行集成。关于如何使用开源代码进行集成，详见 [wiki](https://github.com/polyv/polyv-ios-cloudClass-sdk-demo/wiki)。



## 运行环境

* iOS 9.0 及以上

* XCode 9.0 及以上

* 搭载 iOS 系统的 iPhone, iPad 设备



## 下载安装

手机扫码安装，密码：polyv

![POLYV 云课堂](https://www.pgyer.com/app/qrcode/zrbo)

[下载地址](https://www.pgyer.com/zrbo)



## 支持功能

### 登录

- 直播登录

- 回放登录

  

### 直播

- 普通功能
  - 播放，刷新
  - 视频弹幕
  - 视频码率切换

  - 横竖屏切换
  - 副窗口可随意拖动

- 暖场播放（无直播时播放）

- 手势滑动
  - 屏幕播放区域右方是音量调节区域
  - 播放区域左方是亮度调节区域

- ppt，教师同时在线播放
  - 教师端，ppt 显示切换
  - ppt 的动态画笔功能
  - ppt、教师端的同步播放



### 连麦

- 基本功能
  - 举手连麦
  - 取消举手
  - 断开连麦
  - 横竖屏切换
  - 本地前后摄像头切换

- 多人连麦
  - 同时6人在线连麦
  - 连麦者可以被教师关闭摄像头或者是麦克风

- 连麦的主副屏切换



### 聊天

- 基本功能
  - 设置用户昵称
  - 发言
  - 送花
  - 支持文字和Emoji静态表情的键盘，和文本混排
  - 接收并显示其他端发送的图片(支持gif动图)

  - 支持只看讲师聊天信息

  - 跑马灯公告

  - 欢迎语
  - 回看历史聊天记录

  - 清空聊天信息

  - 删除某条聊天信息

  - 禁言

  - 踢人

  - 私聊

  - 未读消息提醒



### 答题

- 基本功能
  - 竖屏时，在屏幕中间显示教师客户端发送的题目信息（单选题，多选题）
  - 可作答，并提交答案
  - 显示作答结果

 

### 回放

- 基本功能
  - 播放直播的缓存视频
  - 暂停播放
  - 拖动滑动条，可以seek进度播放
  - 视频码率切换
  - 播放倍速切换
  - 横竖屏切换

- 手势滑动
  - 屏幕播放区域右方是音量调节区域
  - 播放区域左方是亮度调节区域
  - 水平左右滑动seek进度播放

- ppt 播放
  - 教师端，ppt 显示切换
  - ppt、教师端的同步回放
  - ppt 与视频播放的快进快退的同步
  - ppt 与视频倍速的同步播放

