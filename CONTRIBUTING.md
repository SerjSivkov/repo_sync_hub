# Участие в разработке Repo Sync Hub

Спасибо, что хотите помочь проекту! Repo Sync Hub — desktop-приложение на Flutter (macOS) для массовой работы с локальными git-репозиториями: сканирование, pull `main`/`master`, push на GitLab.

Репозиторий: [github.com/SerjSivkov/repo_sync_hub](https://github.com/SerjSivkov/repo_sync_hub)

## Содержание

- [Перед началом](#перед-началом)
- [Окружение для разработки](#окружение-для-разработки)
- [Структура проекта](#структура-проекта)
- [Стиль кода и качество](#стиль-кода-и-качество)
- [Сообщения об ошибках](#сообщения-об-ошибках)
- [Предложения улучшений](#предложения-улучшений)
- [Pull Request](#pull-request)
- [Безопасность и секреты](#безопасность-и-секреты)
- [Лицензия](#лицензия)

## Перед началом

1. Ознакомьтесь с [README.md](README.md) — назначение приложения, запуск и сборка.
2. Проверьте [Issues](https://github.com/SerjSivkov/repo_sync_hub/issues): возможно, задача уже обсуждается или кто-то уже работает над ней.
3. Для крупных изменений (новый экран, другой git-host, поддержка Linux) лучше сначала открыть Issue и согласовать подход.

**Текущая платформа:** macOS. PR с поддержкой других платформ приветствуются, но их стоит обсудить заранее.

## Окружение для разработки

### Требования

| Компонент | Версия |
|-----------|--------|
| macOS | актуальная поддерживаемая Apple |
| Flutter | 3.12+ (`flutter --version`) |
| Dart | из состава Flutter (см. `pubspec.yaml`) |
| git | в `PATH` |

### Первый запуск

```bash
git clone https://github.com/SerjSivkov/repo_sync_hub.git
cd repo_sync_hub
flutter pub get
flutter run -d macos
```

### Сборка release

```bash
flutter build macos --release
open build/macos/Build/Products/Release/repo_sync_hub.app
```

### Полезные команды

```bash
flutter analyze          # статический анализ
flutter test             # unit-тесты
flutter pub get          # после изменения pubspec.yaml
```

## Структура проекта

```
lib/
├── main.dart                 # точка входа, тема приложения
├── core/
│   └── app_settings.dart     # настройки (SharedPreferences)
├── models/
│   ├── git_project.dart      # модель репозитория
│   └── scan_progress.dart    # прогресс сканирования
├── services/
│   ├── git_runner.dart       # запуск git-команд
│   ├── git_scanner.dart      # поиск и inspect репозиториев
│   ├── git_operations.dart   # pull / push / sync
│   └── scan_cancellation.dart
└── features/
    ├── home_screen.dart      # главный экран, список, лог
    └── settings_sheet.dart   # настройки GitLab и директории

test/                         # unit-тесты (Dart)
macos/                        # нативная оболочка macOS
```

Новую логику git предпочтительно добавлять в `services/`, UI — в `features/`. Модели не должны вызывать `Process.run` или обращаться к Flutter напрямую.

## Стиль кода и качество

- Следуйте [Effective Dart](https://dart.dev/effective-dart) и правилам из `analysis_options.yaml` (`flutter_lints`).
- UI-тексты для пользователя — **на русском**; идентификаторы, комментарии и commit-сообщения — **на английском** (или русском, если так принято в конкретном PR — главное единообразие в рамках изменения).
- Не оставляйте отладочный код: `print`, закомментированные блоки «на потом», временные `return`/`TODO` без Issue.
- Перед PR убедитесь, что проходят:

```bash
flutter analyze
flutter test
```

Для изменений в git-логике добавляйте или обновляйте тесты в `test/` (см. `test/git_operations_test.dart`).

## Сообщения об ошибках

Создайте [Issue](https://github.com/SerjSivkov/repo_sync_hub/issues/new) с описанием:

1. **Что делали** — шаги воспроизведения (директория, кол-во репозиториев, кнопка Pull/Sync и т.д.).
2. **Ожидание** — что должно было произойти.
3. **Факт** — что произошло (сообщение в UI, строка из лога приложения).
4. **Окружение** — версия macOS, `flutter --version`, `git --version`.
5. **Дополнительно** — скриншот или фрагмент лога (без токенов и URL с паролями).

Если баг связан с конкретным репозиторием, укажите тип (detached HEAD, только `master`, несколько remote и т.п.) **без** публикации приватных URL и токенов.

## Предложения улучшений

Enhancement-тоже через Issues. Полезно указать:

- сценарий использования («синхронизировать 20 Flutter-проектов перед релизом»);
- предлагаемое поведение UI или git-команд;
- альтернативы, если рассматривали.

## Pull Request

1. **Fork** репозитория и создайте ветку от `master`:

   ```bash
   git checkout -b feature/short-description
   # или fix/issue-123-description
   ```

2. Внесите изменения небольшими логическими порциями; один PR — одна тема (фича или багфикс).

3. Обновите документацию, если меняется поведение:
   - [README.md](README.md) — пользовательские сценарии, команды;
   - этот файл — процесс разработки, если он меняется.

4. Убедитесь, что `flutter analyze` и `flutter test` проходят без ошибок.

5. Откройте PR в [SerjSivkov/repo_sync_hub](https://github.com/SerjSivkov/repo_sync_hub) и заполните описание:

   - **Что сделано** — кратко, по делу.
   - **Зачем** — проблема или Issue (`Fixes #123`).
   - **Как проверить** — шаги для ревьюера.

6. Дождитесь review. По замечаниям — правки в той же ветке; force-push допустим до merge.

### Commit-сообщения

Предпочтительный формат:

```
<type>: <short summary in English>

Optional body with details.
```

Типы: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

Примеры:

- `feat: add stop button during repository scan`
- `fix: skip git fetch when scan is cancelled`
- `docs: update CONTRIBUTING for GitHub publish`

## Безопасность и секреты

- **Не коммитьте** GitLab tokens, пароли, приватные URL с credentials, содержимое `.env`, скриншоты с токенами.
- Токен в приложении хранится локально в `SharedPreferences`; в коде и логах не должно быть значений по умолчанию с реальными секретами.
- Приложение запускает `git` на машине пользователя — не добавляйте выполнение произвольных shell-команд из пользовательского ввода без крайней необходимости и валидации.
- Уязвимости безопасности можно сообщить через Issue с пометкой **Security** или приватно maintainer'у (контакт — через профиль GitHub [SerjSivkov](https://github.com/SerjSivkov)), если не хотите публиковать детали сразу.

## Лицензия

Проект распространяется под [GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0).

Отправляя PR или иной вклад, вы соглашаетесь, что ваш код будет лицензирован на тех же условиях. При использовании кода из других проектов указывайте совместимость лицензий и сохраняйте copyright notices.

---

Ещё раз спасибо за участие. Если что-то в этом документе неясно — откройте Issue с предложением по улучшению CONTRIBUTING.
