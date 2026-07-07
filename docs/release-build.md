# Сборка релиза Repo Sync Hub для macOS

Пошагово: версия/тег → release-сборка `.app` → упаковка в DMG + zip.

| Файл | Назначение |
|------|------------|
| `release.dart` | Интерактивный релиз: версия в `pubspec.yaml`, commit, push, тег |
| `scripts/flutter_build_release.sh` | Release-сборка (`flutter build macos --release`) |
| `scripts/macos_nosign.sh` | Отключение codesign для локальной unsigned-сборки |
| `bin/ci/macos_package_dmg.sh` | Упаковка `.app` → `.dmg` + `.zip` в `dist/macos/` |

## 0. Окружение

```bash
flutter --version   # stable
flutter doctor
```

## 1. Версия и тег (опционально)

```bash
dart run release.dart
```

Скрипт предложит версию, обновит `pubspec.yaml`, сделает commit, push и git-тег
(`vX.Y.Z` для stable, `vX.Y.Z-beta.N` / `-alpha.N` для пред-релизов).

## 2. Release-сборка `.app`

```bash
./scripts/flutter_build_release.sh macos
```

Собирает `build/macos/Build/Products/Release/repo_sync_hub.app`
(codesign отключён через `scripts/macos_nosign.sh`).

## 3. Упаковка DMG + zip

```bash
./bin/ci/macos_package_dmg.sh
```

По умолчанию версия берётся из `pubspec.yaml`; можно переопределить меткой:

```bash
APP_RELEASE_LABEL=v1.0.0 ./bin/ci/macos_package_dmg.sh
```

Результат:

```
dist/macos/RepoSyncHub-macos-vX.Y.Z.dmg
dist/macos/RepoSyncHub-macos-vX.Y.Z.zip
```

## Разом (сборка + упаковка)

```bash
./scripts/flutter_build_release.sh macos && ./bin/ci/macos_package_dmg.sh
```
