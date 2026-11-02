# dsh-purge 1.1.39 快照

把一份**能在这台机器上跑通**的 `dsh-purge` 安装留档:插件包 + profile 配置 + 恢复脚本。来源是官方 DeepSeek Harness 桌面客户端,不是插件市场。

## 为什么需要这份快照

`dsh-purge` 的 master 分支已经走到 `1.1.87`,而它声明 `dshTarget: 0.2.1-rc.2`。本机宿主是 **DSH 0.1.7-rc.2**,把 1.1.87 装上去的实测结果:

```
宿主版本 / host  0.1.7-rc.2  ← 未适配:插件声明 0.2.1-rc.2
补丁 5/85 已清洗, 71 待清洗, 5 漂移
```

点 Apply 会被 `lib/core.js:2339` 的硬阻断挡下,返回「清洗没有完成,已取消重启」,宿主文件一个字节都没写入。1.1.7 系宿主必须用 **≤ 1.1.39**,而上游只保留了近期 tag,旧版本只能从 fork 取。

## 内容

| 路径 | 说明 |
|---|---|
| `packages/dsh-purge-1.1.39.tar.gz` | 目标版本,`dshTarget: 0.1.7-rc.2` |
| `packages/dsh-purge-master-1.1.87.tar.gz` | 对照用,不要装到 0.1.7 |
| `profile/desktop/package.json` | 依赖 + bundle 配置 |
| `profile/desktop/cordis.patch.yml` | 用户 patch 层(原样,不含插件 insert) |
| `profile/desktop/pnpm-workspace.yaml` | `allowBuilds` 两条 spec |
| `restore.ps1` | 装回指定 profile |
| `INVENTORY.md` | 版本矩阵、校验和、完整步骤、已知修补点 |

## 版本兼容

| 宿主 DSH | 插件版本 |
|---|---|
| 0.1.7 / 0.1.7-rc.1 / 0.1.7-rc.2 | ≤ 1.1.39 |
| 0.2.0-rc.2 | 1.1.40+ |
| 0.2.1-rc.2 | 1.1.81 / 1.1.87 |

## 恢复

```powershell
# 需要已有的 dsh profile,默认是桌面客户端那个
.\restore.ps1 -ProfileDir "$env:USERPROFILE\.dsh\profiles\desktop"
```

脚本会备份原 `package.json`、放入插件包、写依赖与 bundles、补 `allowBuilds`、用 Harness 自带 pnpm 安装、并执行作者的 `patch-client-dock.mjs`。

装完后:**完全退出宿主再启动** → 会话标题旁按钮 → Clean → Apply → 新开一轮对话 `/purge status`。

## 已知需要手工修的点

1.1.39 的 `package.json` 里 `dsh.client.inject` 少一项 `@deepseek-ai/dsh-client-ui-conversation`,而按钮注册在 `conversation.input.right`(`client.js:7677`),dock 注册在 `shell.overlay`(`7702`)。缺这一项时插件服务端正常、按钮不渲染。补法见 `INVENTORY.md`。

## 校验和

```
3FC6367F9F8365D0902CE088B41DAA181E112E1959C7114D8C718F9BB506519E  packages/dsh-purge-1.1.39.tar.gz        1247985
76643059533A67B1A506FA96E19487D5B3E7780BCC5408D87333B79CC85E6048  packages/dsh-purge-master-1.1.87.tar.gz  2074308
```

## 不含

`~/.dsh/.credentials.yaml`、session 数据、`prompt-inject.md`、宿主 `resources\app` 解包目录。
