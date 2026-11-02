#Requires -Version 5.1
<#
  从本快照恢复 dsh-purge 1.1.39 到指定 dsh profile。
  适用宿主:DSH 0.1.7.x(插件 dshTarget = 0.1.7-rc.2)。
  用法:
    .\restore.ps1 -ProfileDir "$env:USERPROFILE\.dsh\profiles\desktop"
#>
param(
  [Parameter(Mandatory = $true)][string]$ProfileDir,
  [string]$Tarball = (Join-Path $PSScriptRoot 'packages\dsh-purge-1.1.39.tar.gz'),
  [switch]$SkipDockPatch
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ProfileDir)) { throw "profile 不存在: $ProfileDir" }
if (-not (Test-Path $Tarball)) { throw "包不存在: $Tarball" }

$pkgPath = Join-Path $ProfileDir 'package.json'
if (-not (Test-Path $pkgPath)) { throw "缺少 package.json: $pkgPath" }

Copy-Item $pkgPath "$pkgPath.bak-restore" -Force
Copy-Item $Tarball (Join-Path $ProfileDir 'dsh-purge-1.1.39.tar.gz') -Force
Write-Host "[1/5] 已放入插件包,原 package.json 备份为 package.json.bak-restore"

# 依赖 + bundles
$pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
if (-not $pkg.dependencies) { $pkg | Add-Member -NotePropertyName dependencies -NotePropertyValue ([pscustomobject]@{}) }
$pkg.dependencies | Add-Member -NotePropertyName 'dsh-purge' -NotePropertyValue 'file:./dsh-purge-1.1.39.tar.gz' -Force

$bundles = @($pkg.dsh.profile.bundles)
if ($bundles -notcontains 'dsh-purge') { $bundles += 'dsh-purge' }
$pkg.dsh.profile.bundles = $bundles
$pkg | ConvertTo-Json -Depth 12 | Set-Content $pkgPath -Encoding UTF8
Write-Host "[2/5] 已写入依赖与 bundles"

# allowBuilds(避免 pnpm 11 拦 postinstall)
$wsPath = Join-Path $ProfileDir 'pnpm-workspace.yaml'
if (Test-Path $wsPath) {
  $ws = Get-Content $wsPath -Raw
  if ($ws -notmatch 'allowBuilds:') {
    $ws = $ws.TrimEnd() + "`nallowBuilds:`n  dsh-purge: true`n  dsh-purge@file:dsh-purge-1.1.39.tar.gz: true`n"
    Set-Content $wsPath $ws -Encoding UTF8
    Write-Host "[3/5] 已补 allowBuilds"
  } else {
    Write-Host "[3/5] allowBuilds 已存在,若安装报 ERR_PNPM_IGNORED_BUILDS 手工把对应 spec 置 true"
  }
}

# pnpm install(Harness 自带)
$pnpm = Join-Path $env:USERPROFILE '.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\pnpm\bin\pnpm.cjs'
$node = Join-Path $env:USERPROFILE '.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\node\bin\node.exe'
if (-not (Test-Path $pnpm)) { throw "找不到 Harness 自带 pnpm: $pnpm" }

& $node $pnpm install --dir $ProfileDir
if ($LASTEXITCODE -ne 0) { throw "pnpm install 失败(退出码 $LASTEXITCODE),检查 pnpm-workspace.yaml 的 allowBuilds" }
Write-Host "[4/5] pnpm install 完成"

# 客户端 dock(作者脚本,幂等)
if (-not $SkipDockPatch) {
  $dock = Join-Path $ProfileDir 'node_modules\dsh-purge\scripts\patch-client-dock.mjs'
  if (Test-Path $dock) {
    Push-Location (Split-Path $dock -Parent | Split-Path -Parent)
    try { & $node $dock } finally { Pop-Location }
    Write-Host "[5/5] client dock 已打"
  }
}

Write-Host ""
Write-Host "完成。下一步:完全退出宿主 EXE 再启动 -> 会话标题旁按钮 -> Clean -> Apply -> 新开对话 /purge status"
Write-Host "若按钮不出现,按 INVENTORY.md「已知需要手工修的点」给 dsh.client.inject 补 @deepseek-ai/dsh-client-ui-conversation"
