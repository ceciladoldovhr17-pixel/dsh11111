# dsh-purge 安装快照

采集时间:2026-11-02 01:4x(本机)
用途:把能用的插件包与 profile 配置存一份,换机/重装时不必再跟 GitHub 的 tarball 较劲。

## 宿主

| 项 | 值 |
|---|---|
| 宿主 | 官方 DeepSeek Harness 桌面 EXE |
| 安装路径 | `E:\SI\DeepSeek Harness` |
| DSH 核心版本 | **0.1.7-rc.2** |
| profile | `%USERPROFILE%\.dsh\profiles\desktop` |
| 该 profile 由 Electron 独占 | `dsh plugin --profile desktop` 会被 CLI 拒绝,只能改 `package.json` + 自行 `pnpm install` |

## 插件

| 项 | 值 |
|---|---|
| 版本 | **1.1.39** |
| `dshTarget` | `0.1.7-rc.2` |
| 包内是否有 postinstall | 无(1.1.39),bundle patch 自带 insert |
| 清洗状态 | 42/45 已应用,3 条 `missing_file` 跳过(#44、#27、#28) |

## 版本兼容矩阵(据 1.1.87 README 与实测)

| 宿主 DSH | 插件版本 |
|---|---|
| 0.1.7 / 0.1.7-rc.1 / 0.1.7-rc.2 | **≤ 1.1.39** |
| 0.2.0-rc.2 | 1.1.40 或更新 |
| 0.2.1-rc.2 | 1.1.81(1.1.87 亦适用) |
| 0.2.1-rc.3+ | 不支持 |

实测:把 1.1.87 装到 0.1.7-rc.2 上,status 报 `5/85 已清洗,71 待清洗,5 漂移` + `未适配:插件声明 0.2.1-rc.2`;点 Apply 因 `lib/core.js:2339` 的硬阻断返回「清洗没有完成,已取消重启」,宿主文件一个字节都没改。

## 包与校验和

```
3FC6367F9F8365D0902CE088B41DAA181E112E1959C7114D8C718F9BB506519E  packages/dsh-purge-1.1.39.tar.gz        1247985
76643059533A67B1A506FA96E19487D5B3E7780BCC5408D87333B79CC85E6048  packages/dsh-purge-master-1.1.87.tar.gz  2074308
```

来源:

- 1.1.39 — `https://codeload.github.com/mmparko/dsh-purge/tar.gz/refs/tags/v1.1.39`(fork 保留了旧 tag;上游只有近期 tag)
- 1.1.87 — `https://codeload.github.com/YuJunZhiXue/dsh-purge/tar.gz/refs/heads/master`,仅作对照,不要装到 0.1.7

## 恢复步骤

```powershell
# 1) 插件落盘
$profile = "$env:USERPROFILE\.dsh\profiles\desktop"
Copy-Item .\packages\dsh-purge-1.1.39.tar.gz $profile\ -Force

# 2) 依赖与 bundle(参考 profile\desktop\package.json)
#    dependencies.dsh-purge = "file:./dsh-purge-1.1.39.tar.gz"
#    dsh.profile.bundles 追加 "dsh-purge"

# 3) 安装(用 Harness 自带 pnpm)
node "$env:USERPROFILE\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\pnpm\bin\pnpm.cjs" install --dir $profile

# 4) 若 pnpm 报 ERR_PNPM_IGNORED_BUILDS,pnpm-workspace.yaml 的 allowBuilds 置 true 后重跑
#    allowBuilds:
#      dsh-purge: true
#      dsh-purge@file:dsh-purge-1.1.39.tar.gz: true

# 5) 补客户端 dock(可选,作者脚本)
node "$profile\node_modules\dsh-purge\scripts\patch-client-dock.mjs"

# 6) 完全退出宿主再启动,会话标题旁按钮 → Clean → Apply,然后新开对话 /purge status
```

## 已知需要手工修的点

1.1.39 的 `package.json` 中 `dsh.client.inject` 缺 `@deepseek-ai/dsh-client-ui-conversation`,而按钮挂在 `conversation.input.right`(`client.js:7677`),dock 挂在 `shell.overlay`(`7702`)。缺这一项时按钮不渲染。手工补:

```json
"inject": [
  "@deepseek-ai/dsh-client-connection",
  "@deepseek-ai/dsh-client-runtime",
  "@deepseek-ai/dsh-client-locale",
  "@deepseek-ai/dsh-client-ui-slots",
  "@deepseek-ai/dsh-client-ui-settings",
  "@deepseek-ai/dsh-client-ui-conversation"
]
```

`profile/desktop/cordis.patch.yml` 是本机原样:没有 `dsh-purge` 的 insert(1.1.39 的 bundle patch 自己带),`ui-settings` 仍为 `enabled: false`。

## 未包含

- `~/.dsh/.credentials.yaml`、session、`.anonymous-user-id` 等个人数据
- `~/.dsh/prompt-inject.md`(用户文件,34KB,自己维护)
- 宿主 `resources\app` 解包目录(117MB,可由 app.asar 重新解)
