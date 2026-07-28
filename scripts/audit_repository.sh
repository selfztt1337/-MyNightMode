#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() {
  print -u2 "❌ $1"
  exit 1
}

tracked_files=("${(@f)$(git ls-files)}")

for tracked_path in "${tracked_files[@]}"; do
  [[ -e "$tracked_path" ]] || continue
  case "$tracked_path" in
    .vscode/*|.idea/*|*.xcuserstate|*.xcuserdata/*|.DS_Store|dist/*|.build/*)
      fail "Локальный или сгенерированный файл отслеживается Git: $tracked_path"
      ;;
  esac
done

if rg -I -n --hidden \
  -g '!.git/**' \
  -g '!.build/**' \
  -g '!dist/**' \
  -g '!scripts/audit_repository.sh' \
  '(@selfztt1337|/Users/[^/[:space:]]+|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{20,})' .
then
  fail "Найдены персональные маркеры, локальные пути или секреты"
fi

if find . -type f \
  \( -name '.env' -o -name '.env.*' -o -name '*.pem' -o -name '*.p12' -o -name '*.mobileprovision' \) \
  -not -path './.git/*' \
  -not -path './.build/*' \
  -not -path './dist/*' \
  | grep -q .
then
  fail "Найден потенциально чувствительный файл"
fi

local_assets=("${(@f)$(sed -nE 's/.*src="([^"]+)".*/\1/p' README.md | grep -vE '^https?://' || true)}")
for asset in "${local_assets[@]}"; do
  [[ -f "$asset" ]] || fail "README ссылается на отсутствующий файл: $asset"
done

print "✅ Repository privacy and publication audit passed"
