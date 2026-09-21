# Clash for Windows ToolBox

[![GitHub stars](https://img.shields.io/github/stars/xinyitang3/cfwtoolbox?style=social)](https://github.com/xinyitang3/cfwtoolbox/stargazers)
[![Platform](https://img.shields.io/badge/Platform-Windows-blue)]()
[![Clash for Windows](https://img.shields.io/badge/Clash%20for%20Windows-v0.20.39-26A5E4)]()
[![License](https://img.shields.io/badge/License-MIT-green)]()
[![Last Commit](https://img.shields.io/github/last-commit/xinyitang3/cfwtoolbox?label=Last%20Commit)](https://github.com/xinyitang3/cfwtoolbox/commits)

> ⭐ **如果觉得好用，点个 Star 支持一下～**

一个面向 **Clash for Windows v0.20.39** 的命令行工具箱。通过纯 BAT + PowerShell 实现内核切换、内核更新、语言包切换、分流规则注入、Geo 数据库更新等常用运维操作，双击即用。

> [!IMPORTANT]
> **仅支持 Clash for Windows v0.20.39**。
> 其他版本目录结构、asar 语言包、mixin 机制可能不兼容。

---

### 📍 快速导航
- 🚀 [我要部署](#-部署步骤)
- 🧭 [我要了解功能](#-功能说明)
- 🕒 [我要配置 Geo 定时更新](#%EF%B8%8F-geo-定时更新配置)
- 🌐 [CDN 源清单](#-cdn-源清单)
- ❓ [常见问题](#-常见问题)

---

## ✨ 功能特性

| 功能 | 说明 |
| :--- | :--- |
| 🔄 **切换内核** | 在 Mihomo（Meta）和 Premium 之间切换，自动备份当前内核 |
| ⬆️ **更新内核** | 从 GitHub 拉取 Mihomo / Premium 最新版，校验后覆盖 |
| 🌏 **切换语言** | 简体中文 / English 一键切换，缺失语言包自动下载 |
| 🎛️ **控制 Clash** | 启动 / 关闭 / 重启，关闭时自动清理系统代理 |
| 🧹 **整理内核文件** | 按类型重命名，自动补齐缺失的内核文件 |
| 🔍 **查看内核应用** | 检测三个内核文件的实际类型（Meta / Premium） |
| 🧩 **注入分流规则** | 向 Clash for Windows mixin 配置注入 Loyalsoldier 规则集 |
| 🌐 **更新 Geo 数据库** | GeoSite / GeoIP / Country.mmdb / GeoLite2-ASN.mmdb 一键更新 |
| 🔃 **更新脚本** | 从 GitHub 拉取最新版本覆盖本地脚本 |
| 🛡️ **多重 CDN 回退** | 每个下载项配置多个镜像源，逐个尝试，自动切换 |
| 💾 **备份与恢复** | 内核切换前自动备份，保留最近 3 个版本，可一键回滚 |

---

## 📦 文件清单

| 文件 | 说明 |
| :--- | :--- |
| `cfwtoolbox.bat` | 主脚本，包含全部 10 个功能菜单 |
| `Geo update.ps1` | 独立 Geo 更新脚本，供任务计划调用 |
| `Geo update.xml` | Windows 任务计划导入文件（每日自动更新 Geo） |
| `resources\app.asar.zh` | 中文语言包（首次切换语言时自动下载） |
| `resources\app.asar.en` | 英文原版语言包（首次切换语言时自动下载） |
| `resources\static\files\win\x64\` | 内核目录，脚本操作的主要目标 |
| `data\cfw-settings.yaml` | Clash for Windows 配置文件，mixin 注入目标 |
| `resources\static\files\win\x64\kernel-backup\` | 内核备份目录，保留最近 3 个版本 |

---

## 🖥️ 系统要求

- **操作系统**：Windows
- **必备**：Clash for Windows v0.20.39
- **依赖**：PowerShell 5.1（Windows 自带）

---

## 🚀 部署步骤

1. **下载 `cfwtoolbox.bat`**，放到 Clash for Windows 根目录（与 `Clash for Windows.exe` 同级）。

2. **确认目录结构**：
   ```text
   Clash for Windows\
   ├── cfwtoolbox.bat          ← 放在这里
   ├── Clash for Windows.exe
   ├── resources\
   │   ├── app.asar
   │   └── static\files\win\x64\
   │       ├── clash-win64.exe
   │       ├── mihomo.exe
   │       └── premium.exe
   └── data\
       └── cfw-settings.yaml
   ```

3. **双击 `cfwtoolbox.bat`**，看到菜单即部署完成。

4. **（可选）配置 Geo 定时更新**：见 [Geo 定时更新配置](#%EF%B8%8F-geo-定时更新配置)。

---

## 🧭 功能说明

### 1. 切换内核

在当前内核与目标内核之间切换：

- **切换到 Mihomo**：将 `mihomo.exe` 复制为 `clash-win64.exe`
- **切换到 Premium**：将 `premium.exe` 复制为 `clash-win64.exe`

流程：检测目标内核类型 → 停止 Clash for Windows → 备份当前内核 → 覆盖 → 启动 Clash for Windows。

> 💡 如果目标内核文件不存在，会提示是否从 GitHub 下载。

### 2. 更新内核

从 GitHub 拉取最新版本：

| 内核 | 下载源 |
| :--- | :--- |
| Mihomo | `MetaCubeX/mihomo` releases |
| Premium | `Z-Siqi/Clash-for-Windows_Chinese` 仓库 |

更新后提示是否同步到当前内核（覆盖 `clash-win64.exe`）。

### 3. 切换语言

通过替换 `resources\app.asar` 切换 Clash for Windows 界面语言：

- **简体中文**：使用 `app.asar.zh`
- **English**：使用 `app.asar.en`

首次切换时缺失的语言包会自动下载（约 30MB，从 `xinyitang3/cfwtoolbox` 的 `master` 分支）。

> 💡 语言包下载后本地缓存，后续切换不再重复下载。

### 4. 控制 Clash

- **启动**：通过 `Start-Process` 独立启动，不挂在本脚本进程
- **关闭**：`taskkill` 杀掉 Clash for Windows 和内核进程，同时清除系统代理（注册表 + WinINET 刷新）
- **重启**：关闭 + 启动

### 5. 整理内核文件

自动识别内核目录中的 exe 文件类型，按类型重命名：

- Meta 类型 → `mihomo.exe`
- Premium 类型 → `premium.exe`

同时备份所有 exe 到 `resources\static\files\win\x64\kernel-backup\`，保留最近 3 个。

### 6. 查看内核应用

检测并显示三个内核文件的实际类型：

```text
Active  [clash-win64.exe]: Meta
Mihomo  [mihomo.exe]: Meta
Premium [premium.exe]: Premium
```

### 7. 注入分流规则

向 `data\cfw-settings.yaml` 的 `mixinText` 字段注入以下规则：

- `rule-providers`：DIRECT / PROXY / REJECT 三个规则集，来自 Loyalsoldier/clash-rules
- `prepend-rules`：REJECT → PROXY → DIRECT 三条规则前置

> [!WARNING]
> 注入前需**手动在 Clash for Windows 界面开启"混合配置"开关**（开关状态保存在 leveldb，脚本无法修改）。
> 脚本已注入过则自动跳过，如需更新请手动编辑配置文件。

### 8. 更新 Geo 数据库

更新 `data\` 目录下的 4 个数据库文件：

| 文件 | 数据源 |
| :--- | :--- |
| `GeoSite.dat` | Loyalsoldier/v2ray-rules-dat |
| `GeoIP.dat` | Loyalsoldier/v2ray-rules-dat |
| `Country.mmdb` | alecthw/mmdb_china_ip_list |
| `GeoLite2-ASN.mmdb` | xishang0128/geoip |

关闭 Clash for Windows → 下载 → 启动 Clash for Windows。

### 9. 更新脚本

从 GitHub 拉取最新版 `cfwtoolbox.bat` 覆盖本地：

1. 下载到 `%TEMP%\cfwtoolbox_new.bat`
2. 大小 + 文件头双重校验
3. 生成独立 apply 脚本，等主脚本退出后覆盖
4. 自启动新版脚本

### 10. 退出脚本

退出工具箱。

---

## ⚙️ Geo 定时更新配置

`Geo update.ps1` 和 `Geo update.xml` 用于配置 Windows 任务计划，每天自动更新 Geo 数据库。

### 导入任务计划

1. 修改 `Geo update.xml` 中的以下字段，改为你的实际路径：

   ```xml
   <Arguments>-ExecutionPolicy Bypass -WindowStyle Hidden -Command "$s = Join-Path $env:USERPROFILE '.config\clash\Geo update.ps1'; &amp; $s"</Arguments>
   ```

   将 `.config\clash\Geo update.ps1` 替换为你的实际路径，例如：
   ```
   $s = '<你的路径>\Geo update.ps1'; & $s
   ```

2. 打开 **任务计划程序** → **导入任务** → 选择 `Geo update.xml`。

3. 确认触发时间（默认每天 05:00）、运行账户、是否使用最高权限。

### 脚本行为

`Geo update.ps1` 独立运行时：

1. 检测当前是否有 Clash 进程在运行
2. 若在运行，`taskkill` 关闭并记录主程序路径
3. 清除系统代理
4. 从多个镜像下载 4 个 Geo 文件
5. 若之前 Clash 在运行，重启它

### 与主脚本的区别

| 特性 | 主脚本 `cfwtoolbox.bat` | 独立 `Geo update.ps1` |
| :--- | :--- | :--- |
| 运行方式 | 手动双击 | 任务计划自动 |
| 是否关 Clash | 是 | 智能检测 |
| 下载超时 | 60s | 20s |
| 重启 Clash | 总是重启 | 仅在原本运行时重启 |

---

## 🌐 CDN 源清单

所有下载项均配置多个镜像，按顺序尝试，第一个成功即退出。

### 功能 2 / 3 / 9（内核 / 语言包 / 脚本）

1. `ghfast.top`（GitHub 代理）
2. `fastly.jsdelivr.net`（仅脚本更新）
3. `testingcf.jsdelivr.net`（仅脚本更新）
4. `cdn.jsdelivr.net`（仅脚本更新）
5. `raw.githubusercontent.com`（直连）
6. `gh-proxy.com`
7. `mirror.ghproxy.com`

### 功能 8（Geo 数据库）

每个文件 7 个源：

1. `fastly.jsdelivr.net`
2. `ghfast.top`
3. `testingcf.jsdelivr.net`
4. `cdn.jsdelivr.net`
5. `raw.githubusercontent.com`
6. `gh-proxy.com`
7. `mirror.ghproxy.com`

### 功能 7（mixin 规则）

固定使用 `fastly.jsdelivr.net`。

---

## ❓ 常见问题

<details>
<summary>📁 脚本提示"找不到内核目录"</summary>

确认脚本与 `Clash for Windows.exe` 同级，且 `resources\static\files\win\x64\` 目录存在。

</details>

<details>
<summary>🧩 注入分流规则后不生效</summary>

1. 确认 Clash for Windows 界面的**混合配置开关已打开**
2. 检查 `data\cfw-settings.yaml` 中是否有 `mixinText` 字段
3. 如果已注入过（`rule-providers` 关键字存在），脚本会自动跳过，需手动编辑

</details>

<details>
<summary>💾 内核备份占用空间大</summary>

`resources\static\files\win\x64\kernel-backup\` 目录只保留最近 3 个备份，会自动清理。如需手动清理，直接删除该目录即可。

</details>

<details>
<summary>🕒 Geo 定时任务不执行</summary>

1. 检查任务计划程序中任务是否存在且启用
2. 确认 XML 中的 PowerShell 路径正确
3. 确认运行账户有权限访问脚本路径
4. 查看任务历史记录中的错误信息

</details>

<details>
<summary>🚫 关闭 Clash 后系统代理未清除</summary>

脚本关闭 Clash for Windows 时会执行：

- 注册表 `ProxyEnable` 设为 0
- 调用 WinINET `InternetSetOption` 刷新

如果仍无效，手动检查 `设置 → 网络和 Internet → 代理`。

</details>

---

## 🙏 致谢

**主程序与内核**

- Clash for Windows：[Fndroid/clash_for_windows_pkg](https://github.com/Fndroid/clash_for_windows_pkg)
- Mihomo 内核：[MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- Premium 内核：[Z-Siqi/Clash-for-Windows_Chinese](https://github.com/Z-Siqi/Clash-for-Windows_Chinese)

**规则与数据库**

- 规则数据源：[Loyalsoldier/clash-rules](https://github.com/Loyalsoldier/clash-rules)
- Geo 数据源：[Loyalsoldier/v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat)
- Country.mmdb：[alecthw/mmdb_china_ip_list](https://github.com/alecthw/mmdb_china_ip_list)
- ASN 数据库：[xishang0128/geoip](https://github.com/xishang0128/geoip)

**CDN 与代理**

- jsDelivr：[jsdelivr/jsdelivr](https://github.com/jsdelivr/jsdelivr)
- GitHub 加速代理：`ghfast.top`、`gh-proxy.com`、`mirror.ghproxy.com`

---

**许可证**：本项目采用 [MIT License](https://opensource.org/licenses/MIT) 开源。
