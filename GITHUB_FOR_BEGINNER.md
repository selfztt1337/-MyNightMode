# Как выложить MyNightMode в GitHub

## Вариант через терминал VS Code

### 1. Создай пустой репозиторий

На github.com нажми `+` → `New repository`.

Название: `MyNightMode`

Не добавляй README, .gitignore или License: они уже есть в проекте.

### 2. Открой терминал VS Code

`Terminal` → `New Terminal`

Убедись, что терминал открыт в папке MyNightMode.

### 3. Выполни команды

```bash
git init
git add .
git commit -m "Initial MyNightMode release"
git branch -M main
git remote add origin https://github.com/ТВОЙ_ЛОГИН/MyNightMode.git
git push -u origin main
```

Замени `ТВОЙ_ЛОГИН` на свой GitHub username.

При первом push GitHub может попросить авторизацию в браузере.

## Как отправлять следующие версии

```bash
git add .
git commit -m "Improve AI profiles"
git push
```

## Что не попадёт в GitHub

`.gitignore` исключает `.build`, `dist`, DMG и системные файлы macOS. Исходный код и скрипты сборки останутся в репозитории.
