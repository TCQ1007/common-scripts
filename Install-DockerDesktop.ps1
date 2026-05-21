<#
.SYNOPSIS
    交互式安装 Docker Desktop for Windows，支持自定义路径和临时代理。

    不想跑脚本？在 PowerShell 中直接执行下面这条命令（替换变量值）：
    ---
    $exe="Docker Desktop Installer.exe"; $proxy="http://127.0.0.1:7890"; $dir="E:\Software\DockerDesktop"; $data="D:\Software\DockerData"
    & $exe install --quiet --accept-license "--installation-dir=$dir" "--wsl-default-data-root=$data" --user
    ---
    去掉 --user 则为所有用户模式（需要管理员权限）。
    不需要代理则删掉 $proxy 那行和 Remove-Item 那行。

.DESCRIPTION
    该脚本会引导用户指定 Docker Desktop 安装包、代理设置（默认 127.0.0.1:7890）、
    安装模式、程序目录、镜像数据目录（即 WSL 虚拟磁盘位置）。
    使用官方安装参数 --wsl-default-data-root 一次设定所有数据存储位置。
.PARAMETER InstallerPath
    内部参数，提权子进程使用，请勿手动指定。
.PARAMETER ProxyUrl
    内部参数，用于提权后传递代理地址，请勿手动使用。
.PARAMETER PerUser
    内部参数，提权子进程使用，"1"=用户模式，"0"=所有用户模式。
.PARAMETER ProgDir
    内部参数，提权子进程使用，请勿手动指定。
.PARAMETER ImageDataRoot
    内部参数，提权子进程使用，请勿手动指定。
.PARAMETER ChildProcess
    内部参数，提权子进程标识，"1"=跳过交互直接安装。
#>

param(
    [string]$InstallerPath = "",
    [string]$ProxyUrl = "",
    [string]$PerUser = "",
    [string]$ProgDir = "",
    [string]$ImageDataRoot = "",
    [string]$ChildProcess = ""
)

# 设置控制台编码为 UTF-8
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.ForegroundColor = "Cyan"
Write-Host "============================================================"
Write-Host "       Docker Desktop for Windows 智能安装脚本            "
Write-Host "============================================================" -ForegroundColor White
Write-Host ""

# ===================== 交互式输入（仅首次运行） =====================
if ($ChildProcess -ne "1") {

    # ----------------------------- 1. 获取安装包 -----------------------------
    $InstallerPath = Read-Host "请将 Docker Desktop Installer.exe 拖拽到此处，或输入完整路径"
    $InstallerPath = $InstallerPath.Trim(" '")
    if (-not (Test-Path -LiteralPath $InstallerPath -PathType Leaf) -or $InstallerPath -notlike "*.exe") {
        Write-Host "错误：找不到有效的 .exe 安装文件！" -ForegroundColor Red
        pause
        exit 1
    }

    # ----------------------------- 2. 代理配置（仅安装过程） -----------------------------
    Write-Host "`n[代理设置] 仅用于安装过程中的网络下载（如必要组件）" -ForegroundColor Yellow
    $defaultProxy = "http://127.0.0.1:7890"
    Write-Host "默认代理地址: $defaultProxy"
    $modify = Read-Host "是否需要修改默认代理? (y/n, 默认: n)"
    if ($modify -eq "y") {
        $ProxyUrl = Read-Host "请输入代理地址 (例如 http://proxy.example.com:8080 或 socks5://127.0.0.1:1080)"
        if ([string]::IsNullOrWhiteSpace($ProxyUrl)) { $ProxyUrl = "" }
    } else {
        $ProxyUrl = $defaultProxy
    }

    # ----------------------------- 3. 安装模式 -----------------------------
    Write-Host "`n[安装模式选择]" -ForegroundColor Yellow
    Write-Host "1. 用户模式 (推荐，无需管理员权限) - 安装到用户目录"
    Write-Host "2. 所有用户模式 (需要管理员权限) - 安装到 Program Files"
    $modeChoice = Read-Host "请选择 (1 或 2，默认: 1)"
    $PerUser = if ($modeChoice -eq "2") { "0" } else { "1" }
    if ($PerUser -eq "0") {
        Write-Host "注意：所有用户模式需要管理员权限，脚本将尝试自动提升。" -ForegroundColor Cyan
    }

    # ----------------------------- 4. 程序安装目录 -----------------------------
    Write-Host "`n[程序安装位置]" -ForegroundColor Yellow
    $defaultProgDir = if ($PerUser -eq "1") { "$env:LOCALAPPDATA\Programs\DockerDesktop" } else { "C:\Program Files\Docker\Docker" }
    $inputDir = Read-Host "请输入安装路径 (直接回车使用默认: $defaultProgDir)"
    $ProgDir = if ([string]::IsNullOrWhiteSpace($inputDir)) { $defaultProgDir } else { $inputDir }

    # ----------------------------- 5. 镜像/容器数据存放位置（WSL 虚拟磁盘） -----------------------------
    Write-Host "`n[镜像/容器数据存放位置]" -ForegroundColor Yellow
    Write-Host "该位置会存放 WSL 2 虚拟磁盘文件 (.vhdx)，包含所有镜像、容器和卷。"
    Write-Host "建议放在空间充足的非系统盘（如 D:\DockerData）。"
    $ImageDataRoot = Read-Host "请输入目录路径"
    if ([string]::IsNullOrWhiteSpace($ImageDataRoot)) {
        Write-Host "错误：镜像数据存放位置不能为空！" -ForegroundColor Red
        pause
        exit 1
    }
    $invalidChars = [System.IO.Path]::GetInvalidPathChars()
    if ($ImageDataRoot.IndexOfAny($invalidChars) -ge 0) {
        Write-Host "错误：路径包含非法字符！" -ForegroundColor Red
        pause
        exit 1
    }

    # ----------------------------- 6. WSL 发行版安装位置（说明） -----------------------------
    Write-Host "`n[WSL 发行版安装位置]" -ForegroundColor Yellow
    Write-Host "注意：WSL 发行版 (docker-desktop) 的虚拟磁盘文件实际上与镜像数据存放在同一个位置。"
    Write-Host "因此，该位置将自动设置为与上面的镜像数据目录相同。"
    Write-Host "WSL 发行版将安装到: $ImageDataRoot" -ForegroundColor Cyan

    # ----------------------------- 7. 汇总信息 -----------------------------
    Write-Host "`n[安装配置汇总]" -ForegroundColor Green
    Write-Host "安装包路径      : $InstallerPath"
    if ($ProxyUrl) { Write-Host "代理            : $ProxyUrl" } else { Write-Host "代理            : 无" }
    Write-Host "安装模式        : $(if ($PerUser -eq '1') { '用户模式' } else { '所有用户模式' })"
    Write-Host "程序目录        : $ProgDir"
    Write-Host "镜像/容器数据目录: $ImageDataRoot"
    $confirm = Read-Host "`n确认无误? 按 Y 开始安装，其他键取消"
    if ($confirm -ne "Y") {
        Write-Host "安装已取消。"
        pause
        exit 0
    }
}

# ===================== 提权检查 =====================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($PerUser -eq "0" -and -not $isAdmin) {
    Write-Host "检测到需要管理员权限，正在以管理员身份重新运行脚本..." -ForegroundColor Yellow
    # 将所有用户输入传递给子进程，避免重复输入
    $passArgs = @(
        "-InstallerPath `"$InstallerPath`"",
        "-ProxyUrl `"$ProxyUrl`"",
        "-PerUser $PerUser",
        "-ProgDir `"$ProgDir`"",
        "-ImageDataRoot `"$ImageDataRoot`"",
        "-ChildProcess 1"
    )
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-File `"$PSCommandPath`" $($passArgs -join ' ')"
    exit
}

# ===================== 代理设置（安装过程用） =====================
if ($ProxyUrl) {
    $env:HTTP_PROXY = $ProxyUrl
    $env:HTTPS_PROXY = $ProxyUrl
    Write-Host "`n已为本次安装设置临时代理: $ProxyUrl" -ForegroundColor Green
} else {
    Write-Host "`n未使用代理，将直连网络。" -ForegroundColor DarkGray
}

# ===================== 准备安装目录 =====================
if (-not (Test-Path $ImageDataRoot)) {
    New-Item -ItemType Directory -Path $ImageDataRoot -Force | Out-Null
    Write-Host "`n已创建目录: $ImageDataRoot" -ForegroundColor DarkGray
}

# ===================== 执行安装 =====================
$installArgs = @(
    "install"
    "--quiet"
    "--accept-license"
    "--installation-dir=$ProgDir"
    "--wsl-default-data-root=$ImageDataRoot"
)

if ($PerUser -eq "1") {
    $installArgs += "--user"
}

Write-Host "`n正在执行安装命令..." -ForegroundColor DarkGray
Write-Host "$InstallerPath $($installArgs -join ' ')" -ForegroundColor DarkGray

try {
    $process = Start-Process -FilePath $InstallerPath -ArgumentList $installArgs -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "`nDocker Desktop 安装成功！" -ForegroundColor Green
        Write-Host "`n后续步骤："
        Write-Host "1. 从开始菜单启动 Docker Desktop。"
        Write-Host "2. 若要其他 WSL 发行版（如 Ubuntu）中直接使用 docker 命令，请打开 Docker Desktop 设置 -> Resources -> WSL Integration，勾选对应发行版。"
        Write-Host "3. 首次启动可能需要登录 Docker Hub（可选）。"
    } else {
        Write-Host "`n安装失败，退出代码: $($process.ExitCode)" -ForegroundColor Red
        Write-Host "请检查："
        Write-Host "  - 安装包是否完整？"
        Write-Host "  - 目标目录是否可写？"
        Write-Host "  - 如果使用了代理，代理是否有效？"
    }
} catch {
    Write-Host "启动安装程序时发生异常: $_" -ForegroundColor Red
}

# ===================== 清除代理环境变量 =====================
Remove-Item Env:HTTP_PROXY, Env:HTTPS_PROXY -ErrorAction SilentlyContinue
Write-Host "`n已清除临时代理设置。" -ForegroundColor DarkGray

pause