$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Log($msg) {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
}

function Disable-SystemProxy {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f | Out-Null
    try {
        Add-Type 'using System;using System.Runtime.InteropServices;public class W{[DllImport("wininet.dll")]public static extern bool InternetSetOption(IntPtr h,int o,IntPtr b,int l);}'
        [W]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0) | Out-Null
    } catch { }
}

$dest = Join-Path $PSScriptRoot 'data'
if (-not (Test-Path (Join-Path $dest 'cfw-settings.yaml'))) {
    Log "ERROR: CFW data directory not found"
    exit 1
}

$targets = [ordered]@{
    "GeoSite.dat" = @(
        "https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat",
        "https://ghfast.top/https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat",
        "https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat",
        "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat",
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat",
        "https://gh-proxy.com/https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat",
        "https://mirror.ghproxy.com/https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat"
    )
    "GeoIP.dat" = @(
        "https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat",
        "https://ghfast.top/https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat",
        "https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat",
        "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat",
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat",
        "https://gh-proxy.com/https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat",
        "https://mirror.ghproxy.com/https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat"
    )
    "Country.mmdb" = @(
        "https://fastly.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/lite/Country.mmdb",
        "https://ghfast.top/https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/lite/Country.mmdb",
        "https://testingcf.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/lite/Country.mmdb",
        "https://cdn.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/lite/Country.mmdb",
        "https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/lite/Country.mmdb",
        "https://gh-proxy.com/https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/lite/Country.mmdb",
        "https://mirror.ghproxy.com/https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/lite/Country.mmdb"
    )
    "GeoLite2-ASN.mmdb" = @(
        "https://fastly.jsdelivr.net/gh/xishang0128/geoip@release/GeoLite2-ASN.mmdb",
        "https://ghfast.top/https://raw.githubusercontent.com/xishang0128/geoip/release/GeoLite2-ASN.mmdb",
        "https://testingcf.jsdelivr.net/gh/xishang0128/geoip@release/GeoLite2-ASN.mmdb",
        "https://cdn.jsdelivr.net/gh/xishang0128/geoip@release/GeoLite2-ASN.mmdb",
        "https://raw.githubusercontent.com/xishang0128/geoip/release/GeoLite2-ASN.mmdb",
        "https://gh-proxy.com/https://raw.githubusercontent.com/xishang0128/geoip/release/GeoLite2-ASN.mmdb",
        "https://mirror.ghproxy.com/https://raw.githubusercontent.com/xishang0128/geoip/release/GeoLite2-ASN.mmdb"
    )
}

# 检测 Clash 进程，记录主程序路径（用于重启）
$clashProcs = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match 'clash' })
$clashRunning = $clashProcs.Count -gt 0

$clashExePath = $null
foreach ($proc in $clashProcs) {
    try {
        if ($proc.Path -and $proc.Path -match 'Clash for Windows\.exe$') {
            $clashExePath = $proc.Path
            break
        }
    } catch { }
}

# 先关 Clash、清代理、等待
if ($clashRunning) {
    Log "Stopping Clash..."
    cmd /c 'taskkill /F /IM "Clash for Windows.exe" >nul 2>&1'
    cmd /c 'taskkill /F /IM "clash-win64.exe" >nul 2>&1'
    Start-Sleep -Seconds 3
}
Disable-SystemProxy

# 下载
Log "Downloading..."
foreach ($local in $targets.Keys) {
    $output = Join-Path $dest $local
    $tmp = "$output.tmp"
    $ok = $false
    foreach ($url in $targets[$local]) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
            Move-Item -Path $tmp -Destination $output -Force
            $size = [math]::Round((Get-Item $output).Length / 1MB, 2)
            Log "$local OK ($size MB)"
            $ok = $true
            break
        } catch {
            if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
        }
    }
    if (-not $ok) { Log "$local FAIL" }
}

# 重启 Clash
if ($clashRunning -and $clashExePath -and (Test-Path $clashExePath)) {
    Log "Restarting Clash..."
    Start-Process -FilePath $clashExePath -WorkingDirectory (Split-Path $clashExePath -Parent)
}

Log "Done."
exit 0