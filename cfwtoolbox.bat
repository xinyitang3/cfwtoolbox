@echo off
chcp 936 >nul 2>&1
setlocal enabledelayedexpansion
title Clash for Windows ToolBox

set "SCRIPT_DIR=%~dp0"
set "KERNEL_DIR=%SCRIPT_DIR%resources\static\files\win\x64"
set "CFW_EXE=%SCRIPT_DIR%Clash for Windows.exe"
set "META=mihomo.exe"
set "PREMIUM=premium.exe"
set "ACTIVE=clash-win64.exe"
set "BACKUP=kernel-backup"
set "LOCK=%TEMP%\cfw_kernel_mgr.lock"

if not exist "%KERNEL_DIR%" (
    echo 找不到内核目录
    pause
    exit /b 1
)

call :acquire_lock || exit /b 1
call :main
del "%LOCK%" >nul 2>&1
endlocal
exit

:main
:menu
cls
cd /d "%KERNEL_DIR%"
call :detect_type "%ACTIVE%"
echo.
echo Clash for Windows ToolBox
echo.
echo 仅支持 Clash for Windows v0.20.39
echo.
echo 当前内核: !CURTYPE!
echo.
for %%A in ("1. 切换内核" "2. 更新内核" "3. 切换语言" "4. 控制 Clash" "5. 整理内核文件" "6. 查看内核应用" "7. 注入分流规则" "8. 更新 Geo 数据库" "9. 更新脚本" "10. 退出脚本") do echo %%~A
echo.
set /p "CHOICE=选择 [1-10]:"
if "%CHOICE%"=="1" (call :sub_switch & goto menu)
if "%CHOICE%"=="2" (call :sub_update & goto menu)
if "%CHOICE%"=="3" (call :sub_language & goto menu)
if "%CHOICE%"=="4" (call :sub_clash_control & goto menu)
if "%CHOICE%"=="5" (call :tidy 2>nul & goto menu)
if "%CHOICE%"=="6" (call :show_detail 2>nul & goto menu)
if "%CHOICE%"=="7" (call :inject_mixin & goto menu)
if "%CHOICE%"=="8" (call :update_geo & goto menu)
if "%CHOICE%"=="9" (call :update_script & goto menu)
if "%CHOICE%"=="10" exit /b 0
goto menu

:sub_switch
cls
echo.
echo 切换内核
echo.
echo 1. 切换到 Mihomo
echo 2. 切换到 Premium
echo 3. 返回
echo.
set /p "S=选择 [1-3]:"
if "%S%"=="1" (call :do_switch "%META%" "Meta" 2>nul)
if "%S%"=="2" (call :do_switch "%PREMIUM%" "Premium" 2>nul)
exit /b 0

:sub_update
cls
echo.
echo 更新内核
echo.
echo 1. 更新 Mihomo
echo 2. 更新 Premium
echo 3. 返回
echo.
set /p "S=选择 [1-3]:"
if "%S%"=="1" (call :do_update "%META%" "Meta" 2>nul)
if "%S%"=="2" (call :do_update "%PREMIUM%" "Premium" 2>nul)
exit /b 0

:sub_language
cls
echo.
echo 切换语言
echo.
echo 1. 简体中文
echo 2. English
echo 3. 返回
echo.
set /p "S=选择 [1-3]:"
if "%S%"=="1" (call :lang_zh & pause)
if "%S%"=="2" (call :lang_en & pause)
exit /b 0

:lang_zh
call :ensure_lang
if errorlevel 1 exit /b 0
call :stop_clash
copy /Y "%SCRIPT_DIR%resources\app.asar.zh" "%SCRIPT_DIR%resources\app.asar" >nul
if errorlevel 1 (
    echo 覆盖 app.asar 失败
    call :start_clash
    exit /b 1
)
echo 已切换到简体中文
call :start_clash
exit /b 0

:lang_en
call :ensure_lang
if errorlevel 1 exit /b 0
call :stop_clash
copy /Y "%SCRIPT_DIR%resources\app.asar.en" "%SCRIPT_DIR%resources\app.asar" >nul
if errorlevel 1 (
    echo 覆盖 app.asar 失败
    call :start_clash
    exit /b 1
)
echo 已切换到 English
call :start_clash
exit /b 0

:ensure_lang
set "ZH_SRC=%SCRIPT_DIR%resources\app.asar.zh"
set "EN_SRC=%SCRIPT_DIR%resources\app.asar.en"
set "CUR=%SCRIPT_DIR%resources\app.asar"

if not exist "%CUR%" (
    echo 找不到 app.asar
    exit /b 1
)

call :check_lang_file "%ZH_SRC%"
call :check_lang_file "%EN_SRC%"

if not exist "%ZH_SRC%" (
    echo 下载简体中文语言包...
    call :download_lang "zh" "%ZH_SRC%"
    if errorlevel 1 (
        echo 简体中文语言包下载失败
        exit /b 1
    )
)

if not exist "%EN_SRC%" (
    echo 下载英文原版语言包...
    call :download_lang "en" "%EN_SRC%"
    if errorlevel 1 (
        echo 英文原版语言包下载失败
        exit /b 1
    )
)

exit /b 0

:download_lang
set "LANG=%~1"
set "OUT=%~2"
set "TMPFILE=%TEMP%\app.asar.%LANG%.tmp"
if exist "%TMPFILE%" del /F /Q "%TMPFILE%" >nul 2>&1

powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $urls=@('https://ghfast.top/https://raw.githubusercontent.com/xinyitang3/cfwtoolbox/master/app.asar.%LANG%','https://raw.githubusercontent.com/xinyitang3/cfwtoolbox/master/app.asar.%LANG%','https://gh-proxy.com/https://raw.githubusercontent.com/xinyitang3/cfwtoolbox/master/app.asar.%LANG%','https://mirror.ghproxy.com/https://raw.githubusercontent.com/xinyitang3/cfwtoolbox/master/app.asar.%LANG%'); foreach($u in $urls){ try{Invoke-WebRequest -Uri $u -OutFile '%TMPFILE%' -UseBasicParsing -TimeoutSec 300 -ErrorAction Stop; exit 0 }catch{} }; exit 1" || (echo 下载失败 & pause & exit /b 1)
if not exist "%TMPFILE%" (echo 下载文件缺失 & exit /b 1)

for %%F in ("%TMPFILE%") do set "SIZE=%%~zF"
if !SIZE! LSS 20971520 (
    echo 下载文件异常 大小 !SIZE! 字节
    del /F /Q "%TMPFILE%" >nul 2>&1
    exit /b 1
)

copy /Y "%TMPFILE%" "%OUT%" >nul
if errorlevel 1 (
    del /F /Q "%TMPFILE%" >nul 2>&1
    exit /b 1
)
del /F /Q "%TMPFILE%" >nul 2>&1
echo 已保存 %LANG% 语言包
exit /b 0

:check_lang_file
if not exist "%~1" exit /b 0
for %%F in ("%~1") do set "LFSIZE=%%~zF"
if !LFSIZE! LSS 20971520 (
    echo 语言包异常 大小 !LFSIZE! 字节, 将重新下载
    del /F /Q "%~1" >nul 2>&1
)
exit /b 0

:sub_clash_control
cls
echo.
echo 控制 Clash
echo.
echo 1. 启动 Clash
echo 2. 关闭 Clash
echo 3. 重启 Clash
echo 4. 返回
echo.
set /p "S=选择 [1-4]:"
if "%S%"=="1" (call :start_clash & echo Clash 已启动 & pause)
if "%S%"=="2" (call :stop_clash & echo Clash 已关闭 & pause)
if "%S%"=="3" (call :stop_clash & call :start_clash & echo Clash 已重启 & pause)
exit /b 0

:do_switch
cd /d "%KERNEL_DIR%"
call :ensure_source "%~1" "%~2" || exit /b 1
call :detect_type "%ACTIVE%"
if "!CURTYPE!"=="未知" (echo 当前内核类型未知 & pause & exit /b 1)
call :stop_clash
call :backup_active || (echo 备份失败 & pause & exit /b 1)
copy /Y "%~1" "%ACTIVE%" >nul
if errorlevel 1 (
    call :restore_from_backup "%ACTIVE%"
    pause
    exit /b 1
)
echo 已切换到 %~2
call :start_clash
pause
exit /b 0

:do_update
cd /d "%KERNEL_DIR%"
if /I "%~2"=="Meta" (call :download_meta) else (call :download_premium)
if errorlevel 1 exit /b 1
if not exist "%~1" exit /b 1
echo.
echo 新版本:
for /f "tokens=*" %%i in ('"%~1" -v 2^>^&1') do (
    echo %%i
    goto :ver_done
)
:ver_done
echo.
set /p SYNC=同步到当前内核? [Y/N]:
if /I not "!SYNC!"=="Y" (pause & exit /b 0)
call :stop_clash
call :backup_active || (echo 备份失败 & pause & exit /b 1)
copy /Y "%~1" "%ACTIVE%" >nul
if errorlevel 1 (
    call :restore_from_backup "%ACTIVE%"
    pause
    exit /b 1
)
echo 已同步
call :start_clash
pause
exit /b 0

:tidy
cd /d "%KERNEL_DIR%"
echo 整理前:
dir /b *.exe
echo.
if not exist "%BACKUP%" mkdir "%BACKUP%"
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%a"
for %%F in (*.exe) do copy /Y "%%F" "%BACKUP%\!TS!_%%F" >nul
set "TIDY_LIST="
for %%F in (*.exe) do if /I not "%%F"=="%ACTIVE%" set "TIDY_LIST=!TIDY_LIST! %%F"
for %%F in (!TIDY_LIST!) do (
    call :detect_type "%%F"
    if "!CURTYPE!"=="Meta" if /I not "%%F"=="%META%" (
        if exist "%META%" (echo 跳过: %%F) else (
            ren "%%F" "%META%" >nul 2>&1
            if exist "%META%" (echo 整理: %%F -^> %META%) else (echo 失败: %%F)
        )
    )
    if "!CURTYPE!"=="Premium" if /I not "%%F"=="%PREMIUM%" (
        if exist "%PREMIUM%" (echo 跳过: %%F) else (
            ren "%%F" "%PREMIUM%" >nul 2>&1
            if exist "%PREMIUM%" (echo 整理: %%F -^> %PREMIUM%) else (echo 失败: %%F)
        )
    )
)
call :detect_type "%ACTIVE%"
if "!CURTYPE!"=="Meta" if not exist "%META%" (copy /Y "%ACTIVE%" "%META%" >nul && echo 补齐: %META%)
if "!CURTYPE!"=="Premium" if not exist "%PREMIUM%" (copy /Y "%ACTIVE%" "%PREMIUM%" >nul && echo 补齐: %PREMIUM%)
echo.
echo 整理后:
dir /b *.exe
pause
exit /b 0

:show_detail
cd /d "%KERNEL_DIR%"
echo.
if exist "%ACTIVE%" (
    call :detect_type "%ACTIVE%"
    echo Active  [clash-win64.exe]: !CURTYPE!
) else (
    echo Active  [clash-win64.exe]: 不存在
)
if exist "%META%" (
    call :detect_type "%META%"
    echo Mihomo  [mihomo.exe]: !CURTYPE!
) else (
    echo Mihomo  [mihomo.exe]: 不存在
)
if exist "%PREMIUM%" (
    call :detect_type "%PREMIUM%"
    echo Premium [premium.exe]: !CURTYPE!
) else (
    echo Premium [premium.exe]: 不存在
)
echo.
pause
exit /b 0

:update_script
cls
echo.
echo 更新脚本
echo.
echo 正在检查更新...
set "TMPBAT=%TEMP%\cfwtoolbox_new.bat"
if exist "%TMPBAT%" del /F /Q "%TMPBAT%" >nul 2>&1

powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $urls=@('https://ghfast.top/https://raw.githubusercontent.com/xinyitang3/cfwtoolbox/main/cfwtoolbox.bat','https://raw.githubusercontent.com/xinyitang3/cfwtoolbox/main/cfwtoolbox.bat'); foreach($u in $urls){ try{Invoke-WebRequest -Uri $u -OutFile '%TMPBAT%' -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop; exit 0 }catch{} }; exit 1" || (echo 下载失败 & pause & exit /b 1)

if not exist "%TMPBAT%" (echo 下载文件缺失 & pause & exit /b 1)

for %%F in ("%TMPBAT%") do set "SIZE=%%~zF"
if !SIZE! LSS 10240 (
    echo 下载文件异常 大小 !SIZE! 字节
    del /F /Q "%TMPBAT%" >nul 2>&1
    pause
    exit /b 1
)

powershell -NoProfile -Command "if ((Get-Content -Raw -Encoding ASCII '%TMPBAT%') -match '@echo off') { exit 0 } else { exit 1 }" || (echo 下载文件非脚本 & del /F /Q "%TMPBAT%" >nul 2>&1 & pause & exit /b 1)

set "UPDATE_CMD=%TEMP%\cfw_update_apply.bat"
if exist "%UPDATE_CMD%" del /F /Q "%UPDATE_CMD%" >nul 2>&1
(
echo @echo off
echo timeout /t 2 /nobreak ^>nul
echo copy /Y "%TMPBAT%" "%SCRIPT_DIR%cfwtoolbox.bat" ^>nul
echo if not errorlevel 1 goto upd_ok
echo echo 覆盖失败
echo pause
echo exit /b 1
echo :upd_ok
echo del /F /Q "%TMPBAT%" ^>nul 2^>^&1
echo cd /d "%SCRIPT_DIR%"
echo start "" "%SCRIPT_DIR%cfwtoolbox.bat"
) > "%UPDATE_CMD%"

echo 更新已下载，脚本将重启...
start "" cmd /c "%UPDATE_CMD%"
exit

:update_geo
set "GEO_PS1=%TEMP%\cfw_geo.ps1"
if exist "%GEO_PS1%" del "%GEO_PS1%" >nul 2>&1
powershell -NoProfile -Command "$c = [IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::GetEncoding(936)); $m = [regex]::Match($c, '(?m)^::PSBEGIN[\r\n]+(.*)', 'Singleline'); if (-not $m.Success) { exit 1 }; [IO.File]::WriteAllText('%GEO_PS1%', $m.Groups[1].Value, [System.Text.Encoding]::GetEncoding(936))"
if not exist "%GEO_PS1%" (
    echo 提取 PS 代码失败
    pause
    exit /b 1
)
echo 关闭 Clash for Windows...
call :stop_clash
echo 更新 Geo 数据库...
set "CFW_BASE=%SCRIPT_DIR:~0,-1%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%GEO_PS1%" "%CFW_BASE%"
del "%GEO_PS1%" >nul 2>&1
echo 启动 Clash for Windows...
call :start_clash
pause
exit /b 0

:inject_mixin
set "CFG=%SCRIPT_DIR%data\cfw-settings.yaml"

if not exist "%CFG%" (
    echo.
    echo 检测到 Clash for Windows 尚未初始化, 正在首次启动...
    call :start_clash
    echo 等待生成配置文件...
    timeout /t 8 /nobreak >nul
    if not exist "%CFG%" (
        echo.
        echo 启动后仍未生成 cfw-settings.yaml
        echo 请手动打开 Clash for Windows 完成首次初始化后再试
        pause
        exit /b 1
    )
    echo 配置文件已生成
    timeout /t 2 /nobreak >nul
)

powershell -NoProfile -Command "if ((Get-Content -Raw -Encoding UTF8 '%CFG%') -match 'rule-providers') { exit 1 } else { exit 0 }"
if errorlevel 1 (
    echo.
    echo 检测到规则集已配置过, 跳过注入
    echo 如需更新, 请手动编辑 data\cfw-settings.yaml
    pause
    exit /b 0
)

cls
echo.
echo 注入规则集
echo.
echo 接下来将启动 Clash for Windows
echo 请在它打开后完成操作：
echo.
echo 1. 点击 设置
echo 2. 找到 混合配置
echo 3. 打开开关
echo.
echo 准备好后按任意键 Clash for Windows 将自动启动...
pause >nul

call :start_clash
timeout /t 3 /nobreak >nul

cls
echo.
echo 注入规则集
echo.
echo Clash for Windows 已启动
echo 请在 Clash 界面完成操作：
echo 设置 - 混合配置 - 打开开关
echo.
echo 完成后回到本窗口按任意键继续...
pause >nul

cls
echo.
set /p CONFIRM=确认注入规则集配置? [Y/N]: 
if /I not "!CONFIRM!"=="Y" (
    echo.
    echo 已取消
    pause
    exit /b 0
)

echo.
echo 正在关闭 Clash for Windows...
call :stop_clash

echo 正在注入配置...
set "MIXIN_PS1=%TEMP%\cfw_mixin.ps1"
if exist "%MIXIN_PS1%" del "%MIXIN_PS1%" >nul 2>&1
powershell -NoProfile -Command "$c = [IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::GetEncoding(936)); $m = [regex]::Match($c, '(?m)^::MIXINPS[\r\n]+(.*)', 'Singleline'); if (-not $m.Success) { exit 1 }; [IO.File]::WriteAllText('%MIXIN_PS1%', $m.Groups[1].Value, [System.Text.Encoding]::GetEncoding(936))"
if not exist "%MIXIN_PS1%" (
    echo 提取 PS 代码失败
    call :start_clash
    pause
    exit /b 1
)
set "CFW_BASE=%SCRIPT_DIR:~0,-1%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%MIXIN_PS1%" "%CFW_BASE%"
del "%MIXIN_PS1%" >nul 2>&1

echo 正在启动 Clash for Windows...
call :start_clash

echo.
echo 注入完成 Clash for Windows 已重启
echo 如未生效, 请检查混合配置开关
pause
exit /b 0

:acquire_lock
if exist "%LOCK%" (
    set /p OLD_PID=<"%LOCK%"
    if defined OLD_PID (
        set "PROC_NAME="
        for /f "delims=" %%p in ('powershell -NoProfile -Command "try{(Get-Process -Id !OLD_PID! -ErrorAction Stop).ProcessName}catch{''}" 2^>nul') do set "PROC_NAME=%%p"
        if /I "!PROC_NAME!"=="cmd" (
            echo 脚本已在运行 ^(PID: !OLD_PID!^)
            pause
            exit /b 1
        )
    )
    del "%LOCK%" >nul 2>&1
)
set "LAST_PID="
for /f "tokens=2 delims=," %%p in ('tasklist /FI "IMAGENAME eq cmd.exe" /FO CSV /NH 2^>nul') do set "LAST_PID=%%~p"
if not defined LAST_PID set "LAST_PID=0"
echo !LAST_PID! > "%LOCK%"
exit /b 0

:detect_type
set "CURTYPE=未知"
if not exist "%~1" exit /b 0
set "OUT="
for /f "usebackq tokens=* delims=" %%i in (`"%~1" -v 2^>^&1`) do if "!OUT!"=="" set "OUT=%%i"
if "!OUT!"=="" exit /b 0
if not "!OUT:Mihomo=!"=="!OUT!" (set "CURTYPE=Meta" & exit /b 0)
if not "!OUT:Clash=!"=="!OUT!" (set "CURTYPE=Premium" & exit /b 0)
exit /b 0

:backup_file
if not exist "%~1" exit /b 0
if not exist "%BACKUP%" mkdir "%BACKUP%"
for %%F in ("%~1") do set "SRCNAME=%%~nxF"
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%a"
copy /Y "%~1" "%BACKUP%\!TS!_!SRCNAME!" >nul
if errorlevel 1 exit /b 1
for /f "skip=3 delims=" %%F in ('dir /b /o-d "%BACKUP%\*.exe" 2^>nul') do del /F /Q "%BACKUP%\%%F" >nul 2>&1
exit /b 0

:backup_active
call :backup_file "%ACTIVE%"
exit /b %errorlevel%

:restore_from_backup
for %%F in ("%~1") do set "RNAME=%%~nxF"
set "RSRC="
for /f "delims=" %%F in ('dir /b /o-d "%BACKUP%\*_!RNAME!" 2^>nul') do (
    set "RSRC=%BACKUP%\%%F"
    goto :rsrc_found
)
:rsrc_found
if not defined RSRC (echo 未找到备份 & exit /b 1)
copy /Y "!RSRC!" "%~1" >nul
if errorlevel 1 exit /b 1
echo 已从备份恢复
exit /b 0

:cleanup_dl
del /F /Q "%~1" >nul 2>&1
if exist "%~2" rmdir /S /Q "%~2" >nul 2>&1
exit /b 0

:ensure_source
cd /d "%KERNEL_DIR%"
if exist "%~1" exit /b 0
call :detect_type "%ACTIVE%"
if /I "%~2"=="!CURTYPE!" (
    copy /Y "%ACTIVE%" "%~1" >nul
    if errorlevel 1 (echo 生成源文件失败 & exit /b 1)
    echo 已从当前内核生成 %~1
    exit /b 0
)
echo 未找到 %~1
set /p DL=是否下载? [Y/N]:
if /I not "!DL!"=="Y" exit /b 1
if /I "%~2"=="Meta" (call :download_meta) else (call :download_premium)
if errorlevel 1 exit /b 1
if exist "%~1" exit /b 0
exit /b 1

:download_meta
echo 获取最新版本...
set "VF=%TEMP%\mihomo_ver.txt"
if exist "%VF%" del "%VF%" >nul 2>&1
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $urls=@('https://ghfast.top/https://github.com/MetaCubeX/mihomo/releases/latest/download/version.txt','https://github.com/MetaCubeX/mihomo/releases/latest/download/version.txt','https://gh-proxy.com/https://github.com/MetaCubeX/mihomo/releases/latest/download/version.txt','https://mirror.ghproxy.com/https://github.com/MetaCubeX/mihomo/releases/latest/download/version.txt'); foreach($u in $urls){ try{Invoke-WebRequest -Uri $u -OutFile '%VF%' -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop; exit 0 }catch{} }; exit 1" || (echo 版本获取失败 & pause & exit /b 1)
set "VER="
for /f "usebackq tokens=* delims=" %%v in (`powershell -NoProfile -Command "(Get-Content -Raw -Encoding UTF8 '%VF%').Trim()"`) do if "!VER!"=="" set "VER=%%v"
del "%VF%" >nul 2>&1
if "!VER!"=="" (echo 版本为空 & exit /b 1)
set "ZIP=%TEMP%\mihomo.zip"
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $urls=@('https://ghfast.top/https://github.com/MetaCubeX/mihomo/releases/download/!VER!/mihomo-windows-amd64-!VER!.zip','https://github.com/MetaCubeX/mihomo/releases/download/!VER!/mihomo-windows-amd64-!VER!.zip','https://gh-proxy.com/https://github.com/MetaCubeX/mihomo/releases/download/!VER!/mihomo-windows-amd64-!VER!.zip','https://mirror.ghproxy.com/https://github.com/MetaCubeX/mihomo/releases/download/!VER!/mihomo-windows-amd64-!VER!.zip'); foreach($u in $urls){ try{Invoke-WebRequest -Uri $u -OutFile '%ZIP%' -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop; exit 0 }catch{} }; exit 1" || (echo 下载失败 & pause & exit /b 1)
set "EX=%TEMP%\mihomo_ex"
if exist "%EX%" rmdir /S /Q "%EX%" >nul 2>&1
mkdir "%EX%"
powershell -NoProfile -Command "Expand-Archive '%ZIP%' '%EX%' -Force" || (call :cleanup_dl "%ZIP%" "%EX%" & echo 解压失败 & exit /b 1)
set "NEW="
for /r "%EX%" %%F in (*.exe) do if "!NEW!"=="" set "NEW=%%F"
if "!NEW!"=="" (call :cleanup_dl "%ZIP%" "%EX%" & exit /b 1)
call :detect_type "!NEW!"
if not "!CURTYPE!"=="Meta" (call :cleanup_dl "%ZIP%" "%EX%" & exit /b 1)
call :backup_file "%META%"
if errorlevel 1 exit /b 1
copy /Y "!NEW!" "%META%" >nul
if errorlevel 1 (call :restore_from_backup "%META%" & exit /b 1)
echo 已保存
del /F /Q "%ZIP%" >nul 2>&1
rmdir /S /Q "%EX%" >nul 2>&1
exit /b 0

:download_premium
set "PURL=https://raw.githubusercontent.com/Z-Siqi/Clash-for-Windows_Chinese/main/app/clash_core/win_x64/static/files/win/x64/clash-win64.exe"
if "!PURL!"=="" (echo Premium 下载地址未配置 & pause & exit /b 1)
echo 下载 Premium...
set "DL=%TEMP%\premium_dl.exe"
if exist "%DL%" del /F /Q "%DL%" >nul 2>&1
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $urls=@('https://ghfast.top/!PURL!','!PURL!','https://gh-proxy.com/!PURL!','https://mirror.ghproxy.com/!PURL!'); foreach($u in $urls){ try{Invoke-WebRequest -Uri $u -OutFile '%DL%' -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop; exit 0 }catch{} }; exit 1" || (echo 下载失败 & pause & exit /b 1)
if not exist "%DL%" (echo 下载文件缺失 & exit /b 1)
call :detect_type "%DL%"
if not "!CURTYPE!"=="Premium" (
    del /F /Q "%DL%" >nul 2>&1
    echo 下载文件非 Premium ^(实际: !CURTYPE!^)
    pause
    exit /b 1
)
call :backup_file "%PREMIUM%"
if errorlevel 1 (del /F /Q "%DL%" >nul 2>&1 & exit /b 1)
copy /Y "%DL%" "%PREMIUM%" >nul
if errorlevel 1 (
    del /F /Q "%DL%" >nul 2>&1
    call :restore_from_backup "%PREMIUM%"
    exit /b 1
)
echo 已保存为 %PREMIUM%
del /F /Q "%DL%" >nul 2>&1
exit /b 0

:stop_clash
cd /d "%KERNEL_DIR%"
taskkill /F /IM "Clash for Windows.exe" >nul 2>&1
taskkill /F /IM "clash-win64.exe" >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "Add-Type 'using System;using System.Runtime.InteropServices;public class W{[DllImport(\"wininet.dll\")]public static extern bool InternetSetOption(IntPtr h,int o,IntPtr b,int l);}'; [W]::InternetSetOption([IntPtr]::Zero,39,[IntPtr]::Zero,0)" >nul 2>&1
timeout /t 3 /nobreak >nul
exit /b 0

:start_clash
cd /d "%SCRIPT_DIR%"
if exist "%CFW_EXE%" powershell -NoProfile -Command "Start-Process -FilePath '%CFW_EXE%' -WorkingDirectory '%SCRIPT_DIR%'" >nul 2>&1
exit /b 0

exit /b 0

::PSBEGIN
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$base = if ($args.Count -gt 0) { $args[0].TrimEnd('\') } else { $PSScriptRoot }
$dest = Join-Path $base 'data'
if (-not (Test-Path $dest)) { Write-Host "找不到 data 目录"; exit 1 }

$targets = [ordered]@{
    'GeoSite.dat' = @(
        'https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat',
        'https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat',
        'https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat'
    )
    'GeoIP.dat' = @(
        'https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat',
        'https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat',
        'https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat'
    )
    'Country.mmdb' = @(
        'https://fastly.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/lite/Country.mmdb',
        'https://testingcf.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/lite/Country.mmdb',
        'https://cdn.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/lite/Country.mmdb'
    )
    'GeoLite2-ASN.mmdb' = @(
        'https://fastly.jsdelivr.net/gh/xishang0128/geoip@release/GeoLite2-ASN.mmdb',
        'https://testingcf.jsdelivr.net/gh/xishang0128/geoip@release/GeoLite2-ASN.mmdb',
        'https://cdn.jsdelivr.net/gh/xishang0128/geoip@release/GeoLite2-ASN.mmdb'
    )
}

foreach ($local in $targets.Keys) {
    $output = Join-Path $dest $local
    $tmp = "$output.tmp"
    $ok = $false
    foreach ($url in $targets[$local]) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
            Move-Item -Path $tmp -Destination $output -Force
            $size = [math]::Round((Get-Item $output).Length / 1MB, 2)
            Write-Host "$local OK ($size MB)"
            $ok = $true
            break
        } catch {
            if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
        }
    }
    if (-not $ok) { Write-Host "$local FAIL" }
}

exit 0

::MIXINPS
$ErrorActionPreference = 'Continue'

$base = if ($args.Count -gt 0) { $args[0].TrimEnd('\') } else { $PSScriptRoot }
$cfg = Join-Path $base 'data\cfw-settings.yaml'

if (-not (Test-Path $cfg)) {
    Write-Host "找不到 cfw-settings.yaml"
    exit 1
}

$content = Get-Content -Raw -Encoding UTF8 $cfg
if ($content -match 'rule-providers') {
    Write-Host "已检测到 rule-providers 配置, 跳过注入"
    exit 0
}

$rocket = [char]::ConvertFromUtf32(0x1F680)
$mixin = @'
mixin:
  rule-providers:
    DIRECT:
      type: http
      behavior: domain
      url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/direct.txt"
      path: ./ruleset/direct.yaml
      interval: 86400
    PROXY:
      type: http
      behavior: domain
      url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/proxy.txt"
      path: ./ruleset/proxy.yaml
      interval: 86400
    REJECT:
      type: http
      behavior: domain
      url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/reject.txt"
      path: ./ruleset/reject.yaml
      interval: 86400
  prepend-rules:
    - RULE-SET,REJECT,REJECT
    - RULE-SET,PROXY,__ROCKET__ 节点选择
    - RULE-SET,DIRECT,DIRECT
'@

$mixin = $mixin -replace '__ROCKET__', $rocket
$mixin = $mixin.TrimEnd()
$escaped = $mixin -replace '\\','\\' -replace '"','\"' -replace "`r`n",'\r\n' -replace "`n",'\r\n'
$newLine = "mixinText: `"$escaped`""
$content = $content -replace '(?m)^mixinText:.*$', $newLine

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($cfg, $content, $utf8NoBom)

Write-Host "规则集已注入"
exit 0