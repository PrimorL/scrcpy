@echo off
setlocal enabledelayedexpansion
title WiFi 一键投屏 - 中文输入版

rem ============================================================
rem   WiFi 一键投屏（scrcpy 5.0.1 + IME 中文输入）
rem   特性：电脑输入法直接打中文进手机（--ime）
rem   流程：全自动零按键；报错停住并显示原因
rem ============================================================

set "BASE=%USERPROFILE%\scrcpy-ime"
set "SCRCPY=%BASE%\scrcpy.exe"
set "ADB=%BASE%\adb.exe"
set "IME_APK=%BASE%\scrcpy-ime.apk"
rem 国内加速镜像（主 + 备，主失效自动切换；实测 ghfast.top 约 450KB/s，gh-proxy.com 约 158KB/s）
set "MIRROR1=https://ghfast.top"
set "MIRROR2=https://gh-proxy.com"
set "GH_ZIP=https://github.com/PrimorL/scrcpy-ime/releases/download/v5.0.1-ime/scrcpy-win64-ime.zip"
set "GH_APK=https://github.com/PrimorL/scrcpy-ime/releases/download/v5.0.1-ime/scrcpy-ime.apk"
rem 文件真实字节数，用于校验下载完整性（防止下到一半被误判成功）
set "ZIP_SIZE=11271751"
set "APK_SIZE=854819"

echo.
echo  ================================================
echo       WiFi 一键投屏（中文输入版）
echo  ================================================
echo.

rem ================= 第1步：检查/下载 scrcpy =================
if exist "%SCRCPY%" goto :check_apk
echo  [检测] 未找到 scrcpy，正在通过国内镜像下载（约 11MB）...
if not exist "%BASE%" mkdir "%BASE%"
rem 主镜像
set "DL_SIZE=0"
curl -L --connect-timeout 20 --retry 2 -sS -o "%BASE%\scrcpy-win64-ime.zip" "%MIRROR1%/%GH_ZIP%"
if exist "%BASE%\scrcpy-win64-ime.zip" for %%F in ("%BASE%\scrcpy-win64-ime.zip") do set "DL_SIZE=%%~zF"
if "!DL_SIZE!"=="%ZIP_SIZE%" goto :scrcpy_ok
rem 备用镜像
echo  [提示] 主镜像下载不完整，切换备用镜像...
del "%BASE%\scrcpy-win64-ime.zip" >nul 2>&1
set "DL_SIZE=0"
curl -L --connect-timeout 20 --retry 2 -sS -o "%BASE%\scrcpy-win64-ime.zip" "%MIRROR2%/%GH_ZIP%"
if exist "%BASE%\scrcpy-win64-ime.zip" for %%F in ("%BASE%\scrcpy-win64-ime.zip") do set "DL_SIZE=%%~zF"
if "!DL_SIZE!"=="%ZIP_SIZE%" goto :scrcpy_ok
set "ERRMSG=下载 scrcpy 失败（已尝试多个镜像，请检查网络后重试）"
goto :fail

:scrcpy_ok
echo  [检测] 正在解压 scrcpy...
powershell -NoProfile -Command "Expand-Archive -Path '%BASE%\scrcpy-win64-ime.zip' -DestinationPath '%BASE%' -Force"
if not exist "%SCRCPY%" (
    set "ERRMSG=解压 scrcpy 失败，压缩包可能损坏，请删除 %BASE% 后重试"
    goto :fail
)
del "%BASE%\scrcpy-win64-ime.zip" >nul 2>&1
echo  [成功] scrcpy 已就绪
echo.

:check_apk
rem ================= 第2步：检查/下载 APK =================
if exist "%IME_APK%" goto :try_wifi
echo  [检测] 未找到 scrcpy-ime.apk，正在通过国内镜像下载...
rem 主镜像
set "DL_SIZE=0"
curl -L --connect-timeout 20 --retry 2 -sS -o "%IME_APK%" "%MIRROR1%/%GH_APK%"
if exist "%IME_APK%" for %%F in ("%IME_APK%") do set "DL_SIZE=%%~zF"
if "!DL_SIZE!"=="%APK_SIZE%" goto :apk_ok
rem 备用镜像
echo  [提示] 主镜像下载不完整，切换备用镜像...
del "%IME_APK%" >nul 2>&1
set "DL_SIZE=0"
curl -L --connect-timeout 20 --retry 2 -sS -o "%IME_APK%" "%MIRROR2%/%GH_APK%"
if exist "%IME_APK%" for %%F in ("%IME_APK%") do set "DL_SIZE=%%~zF"
if "!DL_SIZE!"=="%APK_SIZE%" goto :apk_ok
set "ERRMSG=下载 scrcpy-ime.apk 失败（已尝试多个镜像，请检查网络后重试）"
goto :fail

:apk_ok
echo  [成功] scrcpy-ime.apk 已就绪
echo.

:try_wifi
rem ================= 第3步：尝试 WiFi 直连 =================
echo  [检测] 正在查找已连接的 WiFi 设备...
"%ADB%" devices > "%TEMP%\adb_raw.txt" 2>nul
set "WIFI_SERIAL="
findstr /v "List" "%TEMP%\adb_raw.txt" > "%TEMP%\adb_tmp.txt" 2>nul
for /f "tokens=1" %%a in ('findstr ":" "%TEMP%\adb_tmp.txt"') do set "WIFI_SERIAL=%%a"
if defined WIFI_SERIAL (
    "%ADB%" -s !WIFI_SERIAL! shell getprop ro.product.model >nul 2>&1
    if not errorlevel 1 (
        set "CAST_SERIAL=!WIFI_SERIAL!"
        goto :cast
    )
    "%ADB%" disconnect !WIFI_SERIAL! >nul 2>&1
)

rem ================= 第4步：引导 USB 连接 =================
echo.
echo  ----------------------------------------------
echo  未检测到 WiFi 连接，请通过 USB 连接手机：
echo   1. 手机开启【开发者选项】和【USB 调试】
echo   2. 用 USB 数据线连接手机和电脑
echo   3. 手机弹窗点【允许 USB 调试】
echo  ----------------------------------------------
echo.
echo  正在等待手机连接并授权（自动检测）...

rem ================= 第5步：等待 USB 授权 =================
set "USB_SERIAL="
set "SHOWED_TIP="
set "WAIT_CNT=0"
:wait_usb
set /a WAIT_CNT+=1
if !WAIT_CNT! gtr 120 (
    set "ERRMSG=等待 USB 授权超时（120 秒），请确认已开启 USB 调试并在手机点允许"
    goto :fail
)
"%ADB%" devices > "%TEMP%\adb_raw.txt" 2>nul
findstr /v "List" "%TEMP%\adb_raw.txt" > "%TEMP%\adb_tmp.txt" 2>nul
findstr /v ":" "%TEMP%\adb_tmp.txt" > "%TEMP%\adb_tmp2.txt" 2>nul
findstr "device" "%TEMP%\adb_tmp2.txt" > "%TEMP%\adb_ok.txt" 2>nul
set "USB_SERIAL="
for /f "tokens=1" %%a in (%TEMP%\adb_ok.txt) do set "USB_SERIAL=%%a"
if defined USB_SERIAL goto :install_ime

findstr /v ":" "%TEMP%\adb_tmp.txt" > "%TEMP%\adb_tmp2.txt" 2>nul
findstr "unauthorized" "%TEMP%\adb_tmp2.txt" > "%TEMP%\adb_unauth.txt" 2>nul
set "UNAUTH="
for /f "tokens=1" %%a in (%TEMP%\adb_unauth.txt) do set "UNAUTH=%%a"
if defined UNAUTH (
    if not defined SHOWED_TIP (
        echo  [提示] 已检测到手机但未授权，请在手机上点【允许 USB 调试】
        set "SHOWED_TIP=1"
    )
    "%ADB%" -s !UNAUTH! shell getprop ro.product.model >nul 2>&1
)
timeout /t 1 >nul
goto :wait_usb

rem ================= 第6步：检查/安装 APK =================
:install_ime
"%ADB%" -s !USB_SERIAL! shell pm list packages > "%TEMP%\pkg.txt" 2>nul
findstr /c:"com.genymobile.scrcpy.ime" "%TEMP%\pkg.txt" >nul 2>&1
if not errorlevel 1 goto :get_ip

echo.
echo  ----------------------------------------------
echo  需要安装 scrcpy-ime 输入法到手机：
echo   若手机弹出安装确认，请点【安装】或【允许】
echo  ----------------------------------------------
echo  正在安装并等待确认...
set "IME_CNT=0"
:try_install
set /a IME_CNT+=1
if !IME_CNT! gtr 60 (
    set "ERRMSG=安装 scrcpy-ime 超时，请确认手机已开启 USB 安装权限并点击安装确认"
    goto :fail
)
"%ADB%" -s !USB_SERIAL! install "%IME_APK%" >nul 2>&1
"%ADB%" -s !USB_SERIAL! shell pm list packages > "%TEMP%\pkg.txt" 2>nul
findstr /c:"com.genymobile.scrcpy.ime" "%TEMP%\pkg.txt" >nul 2>&1
if not errorlevel 1 (
    echo  [成功] scrcpy-ime 已安装
    goto :get_ip
)
timeout /t 2 >nul
goto :try_install

rem ================= 第7步：获取 IP =================
:get_ip
echo  [成功] USB 设备已连接：!USB_SERIAL!
echo  正在获取手机 WiFi IP...
set "IPADDR="
"%ADB%" -s !USB_SERIAL! shell ip route > "%TEMP%\ip_route.txt" 2>nul
for /f "tokens=9 delims= " %%x in (%TEMP%\ip_route.txt) do set "IPADDR=%%x"
if not defined IPADDR (
    "%ADB%" -s !USB_SERIAL! shell ip -f inet addr show wlan0 > "%TEMP%\ip_wlan.txt" 2>nul
    for /f "tokens=2 delims= " %%x in (%TEMP%\ip_wlan.txt) do (
        echo %%x | findstr "." >nul
        if not errorlevel 1 set "IPADDR=%%x"
    )
)
for /f "delims=/" %%y in ("!IPADDR!") do set "IPADDR=%%y"
if not defined IPADDR (
    set "ERRMSG=自动获取手机 IP 失败，请确认手机已连接 WiFi"
    goto :fail
)
echo  手机 IP：!IPADDR!

rem ================= 第8步：开启无线调试 =================
echo  正在开启无线调试（tcpip 5555）...
"%ADB%" -s !USB_SERIAL! tcpip 5555
timeout /t 3 >nul
echo  [成功] 无线调试已开启

rem ================= 第9步：等待拔线 =================
echo.
echo  ----------------------------------------------
echo  请【拔掉 USB 数据线】，脚本将自动检测。
echo  ----------------------------------------------
echo  正在等待拔线...
:wait_unplug
"%ADB%" devices > "%TEMP%\adb_raw.txt" 2>nul
findstr /v "List" "%TEMP%\adb_raw.txt" > "%TEMP%\adb_tmp.txt" 2>nul
findstr /v ":" "%TEMP%\adb_tmp.txt" > "%TEMP%\adb_tmp2.txt" 2>nul
set "STILL_USB="
for /f "tokens=1" %%a in (%TEMP%\adb_tmp2.txt) do set "STILL_USB=%%a"
if defined STILL_USB (
    timeout /t 1 >nul
    goto :wait_unplug
)
echo  [成功] 已检测到拔线

rem ================= 第10步：WiFi 连接 =================
echo  正在通过 WiFi 连接手机...
"%ADB%" connect !IPADDR!:5555
set "CAST_SERIAL=!IPADDR!:5555"
echo.

rem ================= 第11步：启动投屏 =================
:cast
echo  [启动] 正在启动投屏（中文输入模式，60 帧）...
echo  提示：用电脑输入法打字即可直接输入中文到手机
echo  投屏启动后本窗口将自动关闭。
powershell -NoProfile -Command "Start-Process -FilePath '%SCRCPY%' -ArgumentList '--serial=!CAST_SERIAL!','--ime','--video-codec=h265','--max-size=1920','--max-fps=60','--video-bit-rate=10M','--video-buffer=50','--audio-bit-rate=256K','--audio-buffer=100','--turn-screen-off' -WindowStyle Hidden"
exit /b 0

rem ================= 错误处理 =================
:fail
echo.
echo  ================================================
echo   [错误] !ERRMSG!
echo  ================================================
echo.
echo  本窗口将在 30 秒后自动关闭，或按任意键立即关闭。
timeout /t 30 >nul
exit /b 1
