# scrcpy-ime (v5.0.1)

<img src="app/data/scrcpy.svg" width="128" height="128" alt="scrcpy" align="right" />

_pronounced "**scr**een **c**o**py**"_

**scrcpy-ime** is a fork of the official [scrcpy](https://github.com/Genymobile/scrcpy)
that adds one key capability: **type Chinese (or any Unicode text) directly into
the phone using your computer's input method.**

This application mirrors Android devices (video and audio) connected via USB or
[TCP/IP](doc/connection.md#tcpip-wireless) and allows control using the
computer's keyboard and mouse. It does not require _root_ access. It works on
_Linux_, _Windows_, and _macOS_.

![screenshot](assets/screenshot-debian-600.jpg)

## What's different from upstream scrcpy

Upstream scrcpy sends physical key events to the phone. This is great for
Latin scripts, but **Chinese (and other IME-based) input is painful**: the
computer sends keycodes, and the phone's own input method has to compose the
characters — you end up switching between the computer and phone keyboards, or
pasting text manually.

scrcpy-ime solves this by porting the `--ime` sidecar approach from the
[zerofancy/scrcpy](https://github.com/zerofancy/scrcpy) fork onto the latest
upstream (v5.0.1):

- A small input-method APK (`scrcpy-ime.apk`) is installed on the phone.
- With `--ime`, when you type on the computer, scrcpy composes the text in your
  computer's input method and injects the **final Unicode string** directly into
  the phone via the sidecar APK.
- The result: **type Chinese on the computer, and it appears on the phone
  instantly** — no phone keyboard, no copy-paste.

Everything else (all upstream v5.0.1 features) is unchanged.

## Features

It focuses on:

 - **lightness**: native, displays only the device screen
 - **performance**: 30~120fps, depending on the device
 - **quality**: 1920×1080 or above
 - **low latency**: [35~70ms][lowlatency]
 - **low startup time**: ~1 second to display the first image
 - **non-intrusiveness**: nothing is left installed on the Android device
 - **user benefits**: no account, no ads, no internet required
 - **freedom**: free and open source software

[lowlatency]: https://github.com/Genymobile/scrcpy/pull/646

Its features include:
 - **IME text injection** (`--ime`) — type Chinese/Unicode directly from the computer
 - [audio forwarding](doc/audio.md) (Android 11+)
 - [recording](doc/recording.md)
 - [virtual display](doc/virtual-display.md)
 - mirroring with [Android device screen off](doc/device.md#turn-screen-off)
 - [copy-paste](doc/control.md#copy-paste) in both directions
 - [configurable quality](doc/video.md)
 - [camera mirroring](doc/camera.md) (Android 12+)
 - [mirroring as a webcam (V4L2)](doc/v4l2.md) (Linux-only)
 - physical [keyboard][hid-keyboard] and [mouse][hid-mouse] simulation (HID)
 - [gamepad](doc/gamepad.md) support
 - [OTG mode](doc/otg.md)
 - and more…

[hid-keyboard]: doc/keyboard.md#physical-keyboard-simulation
[hid-mouse]: doc/mouse.md#physical-mouse-simulation

## Prerequisites

The Android device requires at least API 21 (Android 5.0).

[Audio forwarding](doc/audio.md) is supported for API >= 30 (Android 11+).

Make sure you [enabled USB debugging][enable-adb] on your device(s).

[enable-adb]: https://developer.android.com/studio/debug/dev-options#enable

On some devices (especially Xiaomi), you might get the following error:

```
Injecting input events requires the caller (or the source of the instrumentation, if any) to have the INJECT_EVENTS permission.
```

In that case, you need to enable [an additional option][control] `USB debugging
(Security Settings)` (this is an item different from `USB debugging`) to control
it using a keyboard and mouse. Rebooting the device is necessary once this
option is set.

[control]: https://github.com/Genymobile/scrcpy/issues/70#issuecomment-373286323

Note that USB debugging is not required to run scrcpy in [OTG mode](doc/otg.md).

## Get the app

Prebuilt binaries for this fork are published on the Releases page:

 - [GitHub Releases](https://github.com/PrimorL/scrcpy-ime/releases)
   - `scrcpy-win64-ime.zip` — Windows 64-bit build with `--ime`
   - `scrcpy-ime.apk` — the input-method sidecar APK (install on the phone)
 - [Gitee Releases](https://gitee.com/PrimorL/scrcpy-ime/releases) (for users in China)

For building from source, see [Build instructions](doc/build.md) and the
[`ime/`](ime/) directory for the sidecar APK.

## Using `--ime` (Chinese input)

1. **Install the sidecar APK** on the phone:
   ```bash
   adb install scrcpy-ime.apk
   ```
   (Or let the one-click script below install it automatically.)

2. **Start scrcpy with `--ime`**:
   ```bash
   scrcpy --ime
   ```

3. Click any text field on the phone, then **type with your computer's input
   method**. The composed Unicode text is injected directly into the phone.

Notes:
 - `--ime` works for the **main display with the SDK keyboard**. It is not
   available in OTG mode.
 - The sidecar APK package name is `com.genymobile.scrcpy.ime`.
 - You can also set the APK location via the `SCRCPY_IME_PATH` environment
   variable if the APK is not next to the executable.

## One-click script (Windows)

A ready-to-use Windows batch script is provided in [`scripts/`](scripts/):

 - [`WiFi一键投屏-中文输入版.bat`](scripts/WiFi一键投屏-中文输入版.bat)

It automates the whole wireless workflow end-to-end, with **zero key presses**:

 1. Downloads `scrcpy.exe` and `scrcpy-ime.apk` automatically if missing
    (via China-friendly GitHub mirrors).
 2. Guides USB authorization.
 3. Installs the sidecar APK on the phone.
 4. Enables wireless debugging (`tcpip 5555`).
 5. Prompts you to unplug the cable, then connects over Wi-Fi.
 6. Starts mirroring with `--ime` (H.265, 1920px, 60fps, 10 Mbps video,
    256 Kbps audio, screen off).

On success the console closes automatically; on any error it stops and prints a
clear message for troubleshooting.

## Must-know tips

 - [Reducing resolution](doc/video.md#size) may greatly improve performance
   (`scrcpy -m1024`)
 - [_Right-click_](doc/mouse.md#mouse-bindings) triggers `BACK`
 - [_Middle-click_](doc/mouse.md#mouse-bindings) triggers `HOME`
 - <kbd>Alt</kbd>+<kbd>f</kbd> toggles [fullscreen](doc/window.md#fullscreen)
 - There are many other [shortcuts](doc/shortcuts.md)

## Usage examples

Here are some common examples. There are many more options, [documented](#user-documentation) in separate pages.

 - Type Chinese directly into the phone using the computer input method:

    ```bash
    scrcpy --ime
    ```

 - Capture the screen in H.265 (better quality), limit the size to 1920, limit
   the frame rate to 60fps, and inject Chinese text via IME:

    ```bash
    scrcpy --video-codec=h265 --max-size=1920 --max-fps=60 --ime
    scrcpy --video-codec=h265 -m1920 --max-fps=60 --ime  # short version
    ```

 - Capture the screen in H.265 with audio, mirroring with the device screen off:

    ```bash
    scrcpy --video-codec=h265 --max-size=1920 --max-fps=60 --turn-screen-off --ime
    ```

 - Start VLC in a new virtual display (separate from the device display):

    ```bash
    scrcpy --new-display=1920x1080 --start-app=org.videolan.vlc
    ```

 - Record the device camera in H.265 at 1920x1080 (and microphone) to an MP4
   file:

    ```bash
    scrcpy --video-source=camera --video-codec=h265 --camera-size=1920x1080 --record=file.mp4
    ```

 - Control the device without mirroring by simulating a physical keyboard and
   mouse (USB debugging not required):

    ```bash
    scrcpy --otg
    ```

## User documentation

The application provides a lot of features and configuration options. They are
documented in the following pages:

 - [Connection](doc/connection.md)
 - [Video](doc/video.md)
 - [Audio](doc/audio.md)
 - [Control](doc/control.md)
 - [Keyboard](doc/keyboard.md)
 - [Mouse](doc/mouse.md)
 - [Gamepad](doc/gamepad.md)
 - [Device](doc/device.md)
 - [Window](doc/window.md)
 - [Recording](doc/recording.md)
 - [Virtual display](doc/virtual-display.md)
 - [Tunnels](doc/tunnels.md)
 - [OTG](doc/otg.md)
 - [Camera](doc/camera.md)
 - [Video4Linux](doc/v4l2.md)
 - [Shortcuts](doc/shortcuts.md)

## Resources

 - [FAQ](FAQ.md)
 - [Build instructions](doc/build.md)
 - [Developers](doc/develop.md)
 - [IME sidecar](ime/) — the input-method APK source

## About this fork

scrcpy-ime is based on upstream [scrcpy](https://github.com/Genymobile/scrcpy)
v5.0.1, with the `--ime` feature ported from
[zerofancy/scrcpy](https://github.com/zerofancy/scrcpy).

The primary development repository is hosted on Gitee
(<https://gitee.com/PrimorL/scrcpy-ime>) and automatically mirrored to GitHub
(<https://github.com/PrimorL/scrcpy-ime>).

Upstream scrcpy is authored and maintained by [@rom1v](https://github.com/rom1v).
This fork only adds the IME input feature on top of it.

## License

    Copyright (C) 2018 Genymobile
    Copyright (C) 2018-2026 Romain Vimont

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
