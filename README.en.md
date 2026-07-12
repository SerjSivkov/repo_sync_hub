# Repo Sync Hub

[Русский](README.md) · **English** · [中文](README.zh.md)

A Flutter tool for macOS for bulk maintenance of local git projects:

- scan **multiple** directories containing repositories;
- **Pull** the `main`/`master` branch (fetch, checkout, `git pull --ff-only`);
- **Push** to any destination git system (GitLab, Gitea, Bitbucket, a self-hosted server);
- **Sync** — pull + push for the selected projects;
- overview of every repository's state: remote updates, commit count, size, last pull date, "abandoned" status.

## Requirements

- macOS
- Flutter 3.12+
- `git` in `PATH`

## Running

```bash
cd repo_sync_hub
flutter pub get
flutter run -d macos
```

## First launch

1. Open **Settings** (gear icon) → **Scan directories** → **Add** —
   you can specify several root folders.
2. If needed, configure the **destination system** (for push):
   - **Host** — `gitlab.com`, `gitea.local`, `git.company.com`, etc.;
   - **Group / namespace** — for example `mobile`;
   - **Remote name** — usually `origin`;
   - **Token** — optional, if the remote is not configured yet.
3. Click **Scan** — the list of all repositories with a `.git` folder is collected.
4. Select projects and click **Pull**, **Push** or **Sync**.

Each button has a tooltip describing the action.

## Repository display

- **Grouping** — repositories are grouped by the child directory one level
  below the scan root. Repositories **with errors** are always placed in a
  separate group at the top.
- **Sorting within a group** — by the most recently pulled changes (freshest on top);
  repositories with no activity for **over a year** are marked **"abandoned"** and moved to the bottom.
- **Two views** (toggle in the header):
  - **flat** — a flat list with group headers; clicking a group header
    collapses/expands it;
  - **tree** — expandable groups.
- **Metric columns** for each repository: commit count, on-disk size,
  last pull date.
- Repositories with commits available on the remote are flagged with a badge
  (a `+N` number); after a successful pull — with a **"received"** label.

## Operations

| Action | What it does |
|--------|--------------|
| Scan | Collects status: branch, default branch, dirty, remotes, commits, size, commit date |
| Pull | `fetch --all`, checkout `main`/`master`, `pull --ff-only` |
| Push | Configures the destination remote (if needed), `git push <remote> <branch>` |
| Sync | Pull, then Push |
| Shortcut | A symlink to the repository on the Desktop |
| Show in Finder / Open in Terminal | Opens the repository folder |

With uncommitted changes, you can enable **stash** before checkout in the settings.

## Cache and scheduling

- **Parallel scanning** — repositories are polled by a pool with a concurrency
  limit (4 at a time by default, adjustable within 1–16), which noticeably
  speeds up scanning dozens of repositories with `fetch`/`du`.
- **Scan cache** — results are kept between runs (`SharedPreferences`).
  On startup data is shown from the cache; fresh repositories (within a
  configurable TTL) are not polled again on re-scan. The last scan date is
  shown in the header.
- **Scheduled scanning** — in the settings you can enable a periodic
  auto-run with a set interval in minutes.

## Theme

Light / dark / system — toggle in the header and in the settings.

## Building a release (.app + DMG)

```bash
./scripts/flutter_build_release.sh macos      # build repo_sync_hub.app (release)
./bin/ci/macos_package_dmg.sh                 # package into dist/macos/*.dmg + *.zip
```

Setting the version/tag is interactive: `dart run release.dart`.
More details — [docs/release-build.md](docs/release-build.md).

## Security

The destination token is stored locally in `SharedPreferences`. If the remote
is already configured in the repository, the token is not required — push goes
through the existing URL.

## Contributing

Bug reports, suggestions and pull requests — see [CONTRIBUTING.md](CONTRIBUTING.md).
Ideas and plans — in [TODO.md](TODO.md).

Repository: [github.com/SerjSivkov/repo_sync_hub](https://github.com/SerjSivkov/repo_sync_hub)

## License

Copyright (C) 2026 Sergey Sivkov

Distributed under the [GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0).
