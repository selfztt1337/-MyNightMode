# Сборка NightMode

## Требования

- macOS 14 или новее;
- Xcode Command Line Tools;
- Swift 5.10 или новее.

Внешних Swift-пакетов и сетевых зависимостей нет.

## Release-сборка

```bash
chmod +x scripts/*.sh
./scripts/build_app.sh
```

Скрипт:

1. проверяет `Info.plist`;
2. собирает release-бинарник;
3. создаёт `dist/NightMode.app`;
4. добавляет Retina-иконки;
5. выполняет локальную ad-hoc подпись;
6. проверяет подпись и запускает smoke-тест.

## Дополнительные команды

```bash
swift build -c debug
swift build -c release
./scripts/make_dmg.sh
./scripts/diagnose.sh
```

Для публичного распространения приложение следует подписать Developer ID и нотариализовать.
