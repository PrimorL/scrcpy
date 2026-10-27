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
rem 下载源：按顺序依次尝试，前一个失败自动切下一个（国内用户 Gitee 直连最快最稳）
rem 源1 = Gitee 直连（国内服务器，速度最快，无需代理）
rem 源2 = ghfast.top 镜像 GitHub（备，实测约 450KB/s）
rem 源3 = gh-proxy.com 镜像 GitHub（第二备，实测约 158KB/s）
set "URL1_ZIP=https://gitee.com/PrimorL/scrcpy-ime/releases/download/v5.0.1-ime/scrcpy-win64-ime.zip"
set "URL2_ZIP=https://ghfast.top/https://github.com/PrimorL/scrcpy-ime/releases/download/v5.0.1-ime/scrcpy-win64-ime.zip"
set "URL3_ZIP=https://gh-proxy.com/https://github.com/PrimorL/scrcpy-ime/releases/download/v5.0.1-ime/scrcpy-win64-ime.zip"
set "URL1_APK=https://gitee.com/PrimorL/scrcpy-ime/releases/download/v5.0.1-ime/scrcpy-ime.apk"
set "URL2_APK=https://ghfast.top/https://github.com/PrimorL/scrcpy-ime/releases/download/v5.0.1-ime/scrcpy-ime.apk"
set "URL3_APK=https://gh-proxy.com/https://github.com/PrimorL/scrcpy-ime/releases/download/v5.0.1-ime/scrcpy-ime.apk"
rem 文件真实字节数，用于校验下载完整性（防止下到一半被误判成功）
set "ZIP_SIZE=11274709"
set "APK_SIZE=854829"

echo.
echo  ================================================
echo       WiFi 一键投屏（中文输入版）
echo  ================================================
echo.

rem ================= 第1步：检查/下载 scrcpy =================
if exist "%SCRCPY%" goto :check_apk
echo  [检测] 未找到 scrcpy，正在通过国内镜像下载（约 11MB）...
if not exist "%BASE%" mkdir "%BASE%"
rem 依次尝试三个下载源
set "TRY=1"
:dl_zip
if !TRY! gtr 3 (
    set "ERRMSG=下载 scrcpy 失败（已尝试 Gitee 及多个镜像，请检查网络后重试）"
    goto :fail
)
if !TRY!==1 echo  [下载] 正在从 Gitee 直连下载（约 11MB）...
if !TRY!==2 echo  [提示] Gitee 下载失败，切换镜像 ghfast.top...
if !TRY!==3 echo  [提示] 镜像失败，切换备用镜像 gh-proxy.com...
set "DL_SIZE=0"
call set "DL_URL=%%URL!TRY!_ZIP%%"
curl -L --connect-timeout 20 --retry 2 -sS -o "%BASE%\scrcpy-win64-ime.zip" "!DL_URL!"
if exist "%BASE%\scrcpy-win64-ime.zip" for %%F in ("%BASE%\scrcpy-win64-ime.zip") do set "DL_SIZE=%%~zF"
if "!DL_SIZE!"=="%ZIP_SIZE%" goto :scrcpy_ok
del "%BASE%\scrcpy-win64-ime.zip" >nul 2>&1
set /a TRY+=1
goto :dl_zip

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
rem 已存在的 APK 也要校验版本（字节数），防止旧版本残留被误用
if exist "%IME_APK%" for %%F in ("%IME_APK%") do if "%%~zF"=="%APK_SIZE%" goto :try_wifi
if exist "%IME_APK%" (
    echo  [检测] 发现旧版本 scrcpy-ime.apk，正在更新...
    del "%IME_APK%" >nul 2>&1
) else (
    echo  [检测] 未找到 scrcpy-ime.apk，正在下载...
)
rem 依次尝试三个下载源
set "TRY=1"
:dl_apk
if !TRY! gtr 3 (
    set "ERRMSG=下载 scrcpy-ime.apk 失败（已尝试 Gitee 及多个镜像，请检查网络后重试）"
    goto :fail
)
if !TRY!==1 echo  [下载] 正在从 Gitee 直连下载 scrcpy-ime.apk...
if !TRY!==2 echo  [提示] Gitee 下载失败，切换镜像 ghfast.top...
if !TRY!==3 echo  [提示] 镜像失败，切换备用镜像 gh-proxy.com...
set "DL_SIZE=0"
call set "DL_URL=%%URL!TRY!_APK%%"
curl -L --connect-timeout 20 --retry 2 -sS -o "%IME_APK%" "!DL_URL!"
if exist "%IME_APK%" for %%F in ("%IME_APK%") do set "DL_SIZE=%%~zF"
if "!DL_SIZE!"=="%APK_SIZE%" goto :apk_ok
del "%IME_APK%" >nul 2>&1
set /a TRY+=1
goto :dl_apk

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
        rem WiFi 快捷通道同样要校验手机上的 IME 版本（旧版会导致投屏失败）
        set "INSTALL_SERIAL=!WIFI_SERIAL!"
        set "WIFI_ONLY=1"
        goto :install_ime
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
if defined USB_SERIAL (
    set "INSTALL_SERIAL=!USB_SERIAL!"
    goto :install_ime
)

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
rem 检查已装版本：若与当前 APK 版本不一致（如旧版 4.1），必须先卸载，
rem 否则 scrcpy 启动时会在 WiFi 连接下尝试升级，容易安装失败导致投屏退出
:install_ime
rem 检查已装版本：若与当前 APK 版本不一致（如旧版 4.1），必须先卸载，
rem 否则 scrcpy 启动时会在 WiFi 连接下尝试升级，容易安装失败导致投屏退出
"%ADB%" -s !INSTALL_SERIAL! shell pm list packages > "%TEMP%\pkg.txt" 2>nul
findstr /c:"com.genymobile.scrcpy.ime" "%TEMP%\pkg.txt" >nul 2>&1
if errorlevel 1 goto :do_install
rem 已安装：校验版本是否匹配
"%ADB%" -s !INSTALL_SERIAL! shell dumpsys package com.genymobile.scrcpy.ime > "%TEMP%\imever.txt" 2>nul
findstr /c:"versionName=5.0.1" "%TEMP%\imever.txt" >nul 2>&1
if not errorlevel 1 (
    echo  [检测] scrcpy-ime 已是最新版本 5.0.1
    if defined WIFI_ONLY goto :cast
    goto :get_ip
)
rem 旧版本处理：WiFi 通道下更新安装容易失败，引导用户插 USB 线
if defined WIFI_ONLY goto :wifi_need_usb
echo  [检测] 手机上的 scrcpy-ime 是旧版本，正在更新（先卸载旧版）...
"%ADB%" -s !INSTALL_SERIAL! uninstall com.genymobile.scrcpy.ime >nul 2>&1
goto :do_install

:wifi_need_usb
echo.
echo  ----------------------------------------------
echo  检测到手机上的 scrcpy-ime 是旧版本，需要更新。
echo  WiFi 下更新安装容易失败，请插入 USB 数据线，
echo  脚本将通过 USB 自动完成更新（无需拔线）...
echo  ----------------------------------------------
echo.
set "WAIT_CNT=0"
:wait_usb_wifi
set /a WAIT_CNT+=1
if !WAIT_CNT! gtr 120 (
    set "ERRMSG=等待 USB 连接超时（120 秒），请插上 USB 数据线并允许 USB 调试后重试"
    goto :fail
)
"%ADB%" devices > "%TEMP%\adb_raw.txt" 2>nul
findstr /v "List" "%TEMP%\adb_raw.txt" > "%TEMP%\adb_tmp.txt" 2>nul
findstr /v ":" "%TEMP%\adb_tmp.txt" > "%TEMP%\adb_tmp2.txt" 2>nul
findstr "device" "%TEMP%\adb_tmp2.txt" > "%TEMP%\adb_ok.txt" 2>nul
set "USB_SERIAL="
for /f "tokens=1" %%a in (%TEMP%\adb_ok.txt) do set "USB_SERIAL=%%a"
if defined USB_SERIAL (
    set "INSTALL_SERIAL=!USB_SERIAL!"
    echo  [成功] 已检测到 USB 连接：!USB_SERIAL!
    echo  [检测] 正在卸载旧版本 scrcpy-ime...
    "%ADB%" -s !INSTALL_SERIAL! uninstall com.genymobile.scrcpy.ime >nul 2>&1
    goto :do_install
)
timeout /t 1 >nul
goto :wait_usb_wifi

:do_install
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
"%ADB%" -s !INSTALL_SERIAL! install "%IME_APK%" >nul 2>&1
"%ADB%" -s !INSTALL_SERIAL! shell pm list packages > "%TEMP%\pkg.txt" 2>nul
findstr /c:"com.genymobile.scrcpy.ime" "%TEMP%\pkg.txt" >nul 2>&1
if not errorlevel 1 (
    echo  [成功] scrcpy-ime 已安装
    if defined WIFI_ONLY goto :cast
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

rem 验证 WiFi 连接是否成功（等待连接建立）
set "CONN_OK="
set "CONN_CNT=0"
:wait_conn
set /a CONN_CNT+=1
if !CONN_CNT! gtr 15 (
    set "ERRMSG=WiFi 连接失败（15 秒未连上 !IPADDR!:5555），请确认手机和电脑在同一 WiFi"
    goto :fail
)
"%ADB%" devices > "%TEMP%\adb_raw.txt" 2>nul
findstr /c:"!IPADDR!:5555" "%TEMP%\adb_raw.txt" > "%TEMP%\conn.txt" 2>nul
findstr /c:"device" "%TEMP%\conn.txt" >nul 2>&1
if not errorlevel 1 set "CONN_OK=1"
if defined CONN_OK goto :conn_ok
timeout /t 1 >nul
goto :wait_conn

:conn_ok
echo  [成功] WiFi 已连接：!CAST_SERIAL!
echo.

rem ================= 第11步：启动投屏 =================
:cast
echo  [启动] 正在启动投屏（中文输入模式，60 帧）...
echo  提示：用电脑输入法打字即可直接输入中文到手机
echo  投屏画面出来后，本窗口会自动关闭。
echo.
rem 用 -WindowStyle Hidden 启动：隐藏控制台窗口（scrcpy 是 console 程序），
rem 但 SDL 投屏窗口会由 scrcpy 自己在首帧后主动显示，不受影响。
powershell -NoProfile -Command "Start-Process -FilePath '%SCRCPY%' -ArgumentList '--serial=!CAST_SERIAL!','--ime','--video-codec=h264','--max-size=1920','--max-fps=60','--video-bit-rate=12M','--video-buffer=50','--audio-bit-rate=256K','--audio-buffer=100','--turn-screen-off' -WindowStyle Hidden"
rem 等待 scrcpy 进程启动
set "CAST_CNT=0"
:wait_cast
set /a CAST_CNT+=1
tasklist /fi "imagename eq scrcpy.exe" /fo csv /nh 2>nul | findstr /i "scrcpy.exe" >nul 2>&1
if not errorlevel 1 goto :cast_started
if !CAST_CNT! gtr 10 (
    echo.
    echo   [错误] 投屏进程未能启动，请检查上方是否有报错。
    goto :fail
)
timeout /t 1 >nul
goto :wait_cast

:cast_started
rem 检测投屏窗口是否已弹出（第一帧画面解码成功才会显示）
echo  正在等待投屏画面出现...
set "WIN_CNT=0"
:wait_win
set /a WIN_CNT+=1
for /f "delims=" %%w in ('powershell -NoProfile -Command "(Get-Process scrcpy -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne '' }).Count"') do set "WIN_N=%%w"
if "!WIN_N!" gtr "0" (
    echo  [成功] 投屏已启动，本窗口即将关闭。
    timeout /t 2 >nul
    exit /b 0
)
if !WIN_CNT! gtr 25 (
    echo.
    echo   [错误] 投屏进程已启动，但 25 秒内未出现画面窗口。
    echo   常见原因：手机未连上、h265 编码不支持、IME 版本不匹配。
    echo.
    rem 杀掉残留 scrcpy，避免后台残留
    taskkill /f /im scrcpy.exe >nul 2>&1
    goto :fail
)
rem 若进程提前退出，说明启动失败，跳出等待并回显错误
tasklist /fi "imagename eq scrcpy.exe" /fo csv /nh 2>nul | findstr /i "scrcpy.exe" >nul 2>&1
if errorlevel 1 goto :cast_exit
timeout /t 1 >nul
goto :wait_win

:cast_exit
echo.
echo   [错误] 投屏进程异常退出（可能是连接失败或 IME 版本问题）。
echo   请重跑脚本；若重复出现，把本窗口上方日志截图反馈。
echo.
chcp 936 >nul
echo  ================================================
echo   [错误] 投屏启动失败，进程已退出。
echo  ================================================
echo.
timeout /t 30 >nul
exit /b 1

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
