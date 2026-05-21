#!/usr/bin/env bash
# 清理 WSL 中从 Windows 复制来的 Zone.Identifier 备用数据流
# 在 WSL 下表现为: 原文件名:Zone.Identifier

set -euo pipefail

DEFAULT_DIRS=(
  "$HOME/scripts"
  "$HOME/workspace/mineru-api-test"
)

usage() {
  cat <<'EOF'
用法: clean_zone.sh [目录...]

无参数时默认清理:
  ~/scripts
  ~/workspace/mineru-api-test

示例:
  clean_zone.sh
  clean_zone.sh ~/scripts ~/some/other/dir
EOF
}

find_zone_streams() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  find "$dir" -type f \( -name '*:Zone.Identifier' -o -name '*Zone.Id*' \) 2>/dev/null
}

count_zone_streams() {
  local dir="$1"
  find_zone_streams "$dir" | wc -l | tr -d ' '
}

delete_zone_streams() {
  local dir="$1" deleted=0
  [ -d "$dir" ] || { echo "  跳过（目录不存在）: $dir"; return 0; }

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if rm -f -- "$file"; then
      deleted=$((deleted + 1))
    else
      echo "  删除失败: $file" >&2
      return 1
    fi
  done < <(find_zone_streams "$dir")

  echo "$deleted"
}

main() {
  local dirs=()
  if [ $# -eq 0 ]; then
    dirs=("${DEFAULT_DIRS[@]}")
  else
    dirs=("$@")
  fi

  local total_before=0 total_deleted=0 total_after=0
  local dir before deleted after

  echo "=== Zone.Identifier 清理 ==="
  echo

  for dir in "${dirs[@]}"; do
    dir=$(realpath -m "$dir" 2>/dev/null || echo "$dir")
    before=$(count_zone_streams "$dir")
    total_before=$((total_before + before))
    echo "目录: $dir"
    echo "  清理前: $before 个"
  done
  echo

  if [ "$total_before" -eq 0 ]; then
    echo "未发现 Zone.Identifier 文件，无需清理。"
    exit 0
  fi

  echo "开始删除..."
  for dir in "${dirs[@]}"; do
    dir=$(realpath -m "$dir" 2>/dev/null || echo "$dir")
    deleted=$(delete_zone_streams "$dir")
    total_deleted=$((total_deleted + deleted))
    echo "  $dir -> 已删除 $deleted 个"
  done
  echo

  echo "清理后检测..."
  for dir in "${dirs[@]}"; do
    dir=$(realpath -m "$dir" 2>/dev/null || echo "$dir")
    after=$(count_zone_streams "$dir")
    total_after=$((total_after + after))
    echo "  $dir -> 剩余 $after 个"
  done
  echo

  echo "汇总: 清理前 $total_before | 已删除 $total_deleted | 剩余 $total_after"
  if [ "$total_after" -eq 0 ]; then
    echo "检测通过: 全部清理干净。"
    exit 0
  else
    echo "检测未通过: 仍有 $total_after 个文件未删除。" >&2
    exit 1
  fi
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

main "$@"
