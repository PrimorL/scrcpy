# scrcpy-ime (v5.0.1)

<img src="app/data/scrcpy.svg" width="128" height="128" alt="scrcpy" align="right" />

_发音为 "**scr**een **c**o**py**"_

**scrcpy-ime** 是官方 [scrcpy](https://github.com/Genymobile/scrcpy) 的一个分支（fork），
在其基础上新增了一项核心能力：**用电脑输入法直接输入中文（或任意 Unicode 文本）到手机**。

本应用可将通过 USB 或 [TCP/IP](doc/connection.md#tcpip-wireless) 连接的 Android 设备（视频和音频）
镜像到电脑，并支持用电脑的键盘和鼠标进行控制。无需 _root_ 权限，支持 _Linux_、_Windows_ 和 _macOS_。

![screenshot](assets/screenshot-debian-600.jpg)

## 与官方 scrcpy 的区别

官方 scrcpy 向手机发送的是**物理按键事件**。这种方式对英文输入很友好，但**中文（及其他依赖输入法的文字）
输入非常痛苦**：电脑发送的是键码，手机端需要靠自己的输入法来组词——你不得不在电脑键盘和手机键盘之间来回切换，
或者手动复制粘贴。

scrcpy-ime 通过将 [zerofancy/scrcpy](https://github.com/zerofancy/scrcpy) 的 `--ime` 方案移植到最新的
官方版本（v5.0.1）上来解决这个问题：

- 在手机上安装一个小巧的输入法 APK（`scrcpy-ime.apk`）。
- 使用 `--ime` 时，你在电脑上打字，scrcpy 会在电脑输入法中完成组词，然后把**最终的 Unicode 字符串**通过
  sidecar APK 直接注入手机。
- 效果：**电脑上打中文，手机里即时出现**——无需手机键盘，无需复制粘贴。

除此之外，官方 v5.0.1 的所有功能均保持不变。

## 特性

本项目专注于：

 - **轻量**：原生实现，只显示设备屏幕
 - **高性能**：30~120fps（取决于设备）
 - **高画质**：1920×1080 或更高
 - **低延迟**：[35~70ms][lowlatency]
 - **启动快**：约 1 秒显示首帧画面
 - **无侵入**：不在 Android 设备上残留任何东西
 - **用户友好**：无需账号、无广告、无需联网
 - **自由**：免费开源软件

[lowlatency]: https://github.com/Genymobile/scrcpy/pull/646

功能包括：
 - **IME 文本注入**（`--ime`）——用电脑输入法直接输入中文/Unicode
 - [音频转发](doc/audio.md)（Android 11+）
 - [录屏](doc/recording.md)
 - [虚拟显示器](doc/virtual-display.md)
 - 镜像时[关闭设备屏幕](doc/device.md#turn-screen-off)
 - 双向[复制粘贴](doc/control.md#copy-paste)
 - [可配置画质](doc/video.md)
 - [摄像头镜像](doc/camera.md)（Android 12+）
 - [作为网络摄像头（V4L2）](doc/v4l2.md)（仅 Linux）
 - 物理[键盘][hid-keyboard]和[鼠标][hid-mouse]模拟（HID）
 - [手柄](doc/gamepad.md)支持
 - [OTG 模式](doc/otg.md)
 - 以及更多……

[hid-keyboard]: doc/keyboard.md#physical-keyboard-simulation
[hid-mouse]: doc/mouse.md#physical-mouse-simulation

## 环境要求

Android 设备需至少为 API 21（Android 5.0）。

[音频转发](doc/audio.md) 支持 API >= 30（Android 11+）。

请确保在设备上[开启了 USB 调试][enable-adb]。

[enable-adb]: https://developer.android.com/studio/debug/dev-options#enable

在某些设备（尤其是小米）上，你可能会遇到以下错误：

```
Injecting input events requires the caller (or the source of the instrumentation, if any) to have the INJECT_EVENTS permission.
```

此时，你需要额外开启「**USB 调试（安全设置）**」这一选项（它和「USB 调试」是两个不同的选项），
才能用键盘鼠标进行控制。设置后需重启设备。

[control]: https://github.com/Genymobile/scrcpy/issues/70#issuecomment-373286323

注意：以 [OTG 模式](doc/otg.md) 运行 scrcpy 时无需开启 USB 调试。

## 获取应用

本分支的预编译成品发布在 Releases 页面：

 - [GitHub Releases](https://github.com/PrimorL/scrcpy-ime/releases)
   - `scrcpy-win64-ime.zip` —— 带 `--ime` 的 Windows 64 位完整程序
   - `scrcpy-ime.apk` —— 输入法 sidecar APK（安装到手机）
 - [Gitee Releases](https://gitee.com/PrimorL/scrcpy-ime/releases)（国内用户推荐）

从源码构建请参阅 [构建说明](doc/build.md)，sidecar APK 的源码见 [`ime/`](ime/) 目录。

## 使用 `--ime`（中文输入）

1. **在手机上安装 sidecar APK**：
   ```bash
   adb install scrcpy-ime.apk
   ```
   （也可以让下面的一键脚本自动安装。）

2. **带 `--ime` 启动 scrcpy**：
   ```bash
   scrcpy --ime
   ```

3. 点击手机上的任意文本输入框，然后**用电脑输入法打字**。组好的 Unicode 文本会直接注入到手机。

注意：
 - `--ime` 仅适用于**主显示器 + SDK 键盘**场景，OTG 模式下不可用。
 - sidecar APK 的包名是 `com.genymobile.scrcpy.ime`。
 - 如果 APK 不在可执行文件旁，也可以通过环境变量 `SCRCPY_IME_PATH` 指定其路径。

## 一键脚本（Windows）

在 [`scripts/`](scripts/) 目录中提供了一个开箱即用的 Windows 批处理脚本：

 - [`WiFi一键投屏-中文输入版.bat`](scripts/WiFi一键投屏-中文输入版.bat)

它实现了**全程零按键**的端到端无线投屏流程：

 1. 若缺少 `scrcpy.exe` 和 `scrcpy-ime.apk`，自动下载（走国内友好的 GitHub 加速镜像）。
 2. 引导 USB 授权。
 3. 在手机上自动安装 sidecar APK。
 4. 开启无线调试（`tcpip 5555`）。
 5. 提示拔掉数据线，然后通过 Wi-Fi 连接。
 6. 带 `--ime` 启动镜像（H.265、1920px、60fps、10 Mbps 视频、256 Kbps 音频、息屏）。

成功后控制台自动关闭；出错时脚本会停住并打印清晰的原因，方便排查。

## 必知技巧

 - [降低分辨率](doc/video.md#size) 可大幅提升性能（`scrcpy -m1024`）
 - [_右键_](doc/mouse.md#mouse-bindings) 触发 `返回`
 - [_中键_](doc/mouse.md#mouse-bindings) 触发 `主页`
 - <kbd>Alt</kbd>+<kbd>f</kbd> 切换[全屏](doc/window.md#fullscreen)
 - 还有很多其他[快捷键](doc/shortcuts.md)

## 使用示例

以下是一些常见示例。更多选项请参阅[用户文档](#用户文档)。

 - 用电脑输入法直接向手机输入中文：

    ```bash
    scrcpy --ime
    ```

 - 以 H.265 编码（画质更好）、限制尺寸 1920、限制帧率 60fps，并通过 IME 注入中文：

    ```bash
    scrcpy --video-codec=h265 --max-size=1920 --max-fps=60 --ime
    scrcpy --video-codec=h265 -m1920 --max-fps=60 --ime  # 简写
    ```

 - 以 H.265 编码带音频，镜像时关闭设备屏幕：

    ```bash
    scrcpy --video-codec=h265 --max-size=1920 --max-fps=60 --turn-screen-off --ime
    ```

 - 在新的虚拟显示器中启动 VLC（与设备屏幕分离）：

    ```bash
    scrcpy --new-display=1920x1080 --start-app=org.videolan.vlc
    ```

 - 以 H.265 录制设备摄像头（含麦克风）为 1920x1080 的 MP4 文件：

    ```bash
    scrcpy --video-source=camera --video-codec=h265 --camera-size=1920x1080 --record=file.mp4
    ```

 - 通过模拟物理键盘鼠标来无镜像控制设备（无需 USB 调试）：

    ```bash
    scrcpy --otg
    ```

## 用户文档

本应用提供了大量功能和配置选项，记录在以下页面：

 - [连接](doc/connection.md)
 - [视频](doc/video.md)
 - [音频](doc/audio.md)
 - [控制](doc/control.md)
 - [键盘](doc/keyboard.md)
 - [鼠标](doc/mouse.md)
 - [手柄](doc/gamepad.md)
 - [设备](doc/device.md)
 - [窗口](doc/window.md)
 - [录屏](doc/recording.md)
 - [虚拟显示器](doc/virtual-display.md)
 - [隧道](doc/tunnels.md)
 - [OTG](doc/otg.md)
 - [摄像头](doc/camera.md)
 - [Video4Linux](doc/v4l2.md)
 - [快捷键](doc/shortcuts.md)

## 资源

 - [常见问题（FAQ）](FAQ.md)
 - [构建说明](doc/build.md)
 - [开发者文档](doc/develop.md)
 - [IME sidecar](ime/) —— 输入法 APK 源码

## 关于本分支

scrcpy-ime 基于官方 [scrcpy](https://github.com/Genymobile/scrcpy) v5.0.1，
并将 [zerofancy/scrcpy](https://github.com/zerofancy/scrcpy) 的 `--ime` 功能移植到了最新版本。

主开发仓库托管在 Gitee（<https://gitee.com/PrimorL/scrcpy-ime>），并自动镜像到 GitHub
（<https://github.com/PrimorL/scrcpy-ime>）。

官方 scrcpy 由 [@rom1v](https://github.com/rom1v) 开发维护，本分支仅在其基础上新增了 IME 输入功能。

## 许可证

    Copyright (C) 2018 Genymobile
    Copyright (C) 2018-2026 Romain Vimont

    基于 Apache License 2.0 协议授权（以下简称"协议"）；
    除非遵守该协议，否则你不得使用本文件。
    你可以在以下地址获取协议副本：

        http://www.apache.org/licenses/LICENSE-2.0

    除非适用法律要求或书面同意，按协议分发的软件均按"原样"提供，
    不附带任何明示或暗示的担保或条件。
    有关协议下的具体权限和限制，请参阅协议文本。
