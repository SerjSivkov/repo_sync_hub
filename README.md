# Repo Sync Hub

macOS-инструмент на Flutter для массовой работы с локальными git-проектами:

- сканирование директории с репозиториями;
- **Pull** ветки `main` или `master` (fetch, checkout, `git pull --ff-only`);
- **Push** на GitLab (`gitlab.com` по умолчанию);
- **Sync** — pull + push для выбранных проектов.

## Требования

- macOS
- Flutter 3.12+
- `git` в PATH

## Запуск

```bash
cd /Users/serjsivkov/flutter/repo_sync_hub
flutter pub get
flutter run -d macos
```

## Первый запуск

1. Нажмите **Директория** → укажите корень, например  
   `/Users/serjsivkov/flutter`
2. В настройках задайте:
   - **GitLab host** — `gitlab.com`
   - **GitLab group** — `mobile`
   - **Token** — опционально, если remote ещё не настроен
   - **Имя remote** — обычно `origin`
3. **Сканировать** — список всех подпапок с `.git`
4. Выберите проекты и нажмите **Pull**, **Push GitLab** или **Sync**

При сканировании показывается progress bar, счётчик `OK / ошибок`, а репозитории с доступными коммитами на remote отмечаются справа (иконка + число). После успешного pull — метка **«получены»**.

## Операции

| Действие | Что делает |
|----------|------------|
| Сканировать | Собирает статус: ветка, default branch, dirty, remotes |
| Pull | `fetch --all`, checkout `main`/`master`, `pull --ff-only` |
| Push GitLab | Настраивает remote (если нужно), `git push origin <branch>` |
| Sync | Pull, затем Push |

При незакоммиченных изменениях перед checkout можно включить **stash** в настройках.

## Сборка .app

```bash
flutter build macos --release
open build/macos/Build/Products/Release/repo_sync_hub.app
```

## Безопасность

GitLab token хранится локально в `SharedPreferences`. Если remote уже настроен в репозитории, token не обязателен — push идёт через существующий URL.
