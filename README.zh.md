# Repo Sync Hub

[Русский](README.md) · [English](README.en.md) · **中文**

基于 Flutter 的 macOS 工具，用于批量维护本地 git 项目：

- 扫描**多个**包含仓库的目录；
- **Pull** 拉取 `main`/`master` 分支（fetch、checkout、`git pull --ff-only`）；
- **Push** 推送到任意目标 git 系统（GitLab、Gitea、Bitbucket、自建服务器）；
- **Sync** — 对所选项目执行 pull + push；
- 概览所有仓库的状态：远端更新、提交数、大小、上次拉取日期、"废弃"状态。

## 环境要求

- macOS
- Flutter 3.12+
- `git` 已加入 `PATH`

## 运行

```bash
cd repo_sync_hub
flutter pub get
flutter run -d macos
```

## 首次启动

1. 打开**设置**（齿轮图标）→ **扫描目录** → **添加** —
   可以指定多个根目录。
2. 如有需要，配置**目标系统**（用于 push）：
   - **主机** — `gitlab.com`、`gitea.local`、`git.company.com` 等；
   - **组 / 命名空间** — 例如 `mobile`；
   - **远端名称** — 通常为 `origin`；
   - **令牌（Token）** — 可选，如果远端尚未配置。
3. 点击**扫描** — 收集所有包含 `.git` 的仓库列表。
4. 选择项目并点击 **Pull**、**Push** 或 **Sync**。

每个按钮都有说明其操作的提示（tooltip）。

## 仓库展示

- **分组** — 仓库按扫描根目录下一级的子目录进行分组。**有错误**的
  仓库始终单独归为一组置于顶部。
- **组内排序** — 按最近拉取的变更排序（最新的在上方）；
  **超过一年**无活动的仓库被标记为**"废弃"**并移到底部。
- **两种视图**（在标题栏切换）：
  - **平铺** — 带分组标题的平铺列表；点击分组标题可
    折叠/展开该组；
  - **树形** — 可展开的分组。
- 每个仓库的**指标列**：提交数、磁盘占用大小、
  上次拉取日期。
- 远端有可用提交的仓库会标注徽章（`+N` 数字）；
  成功拉取后显示**"已获取"**标记。

## 操作

| 操作 | 作用 |
|------|------|
| 扫描 | 收集状态：分支、默认分支、dirty、远端、提交、大小、提交日期 |
| Pull | `fetch --all`、checkout `main`/`master`、`pull --ff-only` |
| Push | 配置目标远端（如需要），`git push <remote> <branch>` |
| Sync | 先 Pull，再 Push |
| 快捷方式 | 在桌面创建仓库的软链接 |
| 在 Finder 中显示 / 在终端中打开 | 打开仓库文件夹 |

存在未提交更改时，可在设置中启用 checkout 前的 **stash**。

## 缓存与计划任务

- **并行扫描** — 仓库通过带并发上限的线程池轮询（默认 4 个并发，
  可在 1–16 范围内调整），显著加快对数十个仓库执行
  `fetch`/`du` 的扫描速度。
- **扫描缓存** — 结果在多次运行之间保留（`SharedPreferences`）。
  启动时从缓存展示数据；新鲜的仓库（在可配置的 TTL 内）
  在重新扫描时不会再次轮询。上次扫描日期显示在标题栏。
- **计划扫描** — 可在设置中启用按分钟间隔的定期
  自动运行。

## 主题

浅色 / 深色 / 跟随系统 — 在标题栏和设置中切换。

## 构建发布版（.app + DMG）

```bash
./scripts/flutter_build_release.sh macos      # 构建 repo_sync_hub.app（release）
./bin/ci/macos_package_dmg.sh                 # 打包为 dist/macos/*.dmg + *.zip
```

设置版本/标签是交互式的：`dart run release.dart`。
更多细节 — [docs/release-build.md](docs/release-build.md)。

## 安全

目标令牌本地存储在 `SharedPreferences` 中。如果仓库中已配置远端，
则无需令牌 — push 会通过已有的 URL 进行。

## 参与开发

Bug 报告、建议和 pull request — 参见 [CONTRIBUTING.md](CONTRIBUTING.md)。
想法和计划 — 参见 [TODO.md](TODO.md)。

仓库地址：[github.com/SerjSivkov/repo_sync_hub](https://github.com/SerjSivkov/repo_sync_hub)

## 许可证

Copyright (C) 2026 Sergey Sivkov

本项目基于 [GNU Affero General Public License v3.0](LICENSE)（AGPL-3.0）分发。
