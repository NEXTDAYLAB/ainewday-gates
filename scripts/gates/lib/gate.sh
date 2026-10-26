#!/usr/bin/env bash
# Thư viện chung cho MỌI cổng của chuỗi gate-chain (chuẩn GATES nội bộ §1 — ba trạng thái).
# Khái quát từ một dự án nội bộ scripts/lib/gate.sh (bản đang chạy thật từ 07/09/2026).
#
# Dùng trong check-<tên>.sh:
#   source "$(dirname "$0")/lib/gate.sh"
#   gate_init "<tên>" "$@"
#   ... gate_violation "file:dòng — mô tả" ...
#   gate_finish
#
# Mã thoát: 0 = đạt · 1 = vi phạm (đã in danh sách) · 2 = GATE BROKEN (không chạy được).
# Không bao giờ quy "không chạy được" về 0 vi phạm. Không in mã màu.
#
# Tham số chung:  --root DIR   quét DIR thay vì repo (chế độ fixture, không dùng git)
#                 --base REF   ref gốc để so (mặc định $GATE_BASE_REF hoặc origin/main)
#                 --no-color   chấp nhận cho tương thích; cổng vốn không in màu
#
# Biến môi trường (repo gọi đặt qua input của workflow gate-chain):
#   GATE_DIR        thư mục cổng riêng của repo      (mặc định: scripts)
#   GATE_REGISTRY   sổ cổng                           (mặc định: docs/GATES.md)
#   GATE_PITFALLS   sổ án lệ                          (mặc định: docs/PITFALLS.md)
#   GATE_TODAY      ngày hôm nay YYYY-MM-DD (fixture) (mặc định: date +%F)
set -u

GATE_EXIT_PASS=0
GATE_EXIT_FAIL=1
GATE_EXIT_BROKEN=2

gate_broken() {
  printf 'GATE %s: BROKEN - %s\n' "${GATE_NAME:-?}" "$*" >&2
  exit "$GATE_EXIT_BROKEN"
}

gate_require_tool() {
  command -v "$1" >/dev/null 2>&1 || gate_broken "thiếu công cụ '$1' — cài trước khi chạy (workflow gate-chain cài sẵn)"
}

gate_init() {
  GATE_NAME="$1"; shift
  # Công cụ lõi: thiếu là BROKEN, không phải "0 vi phạm".
  local t
  for t in awk sed grep find sort wc tr date mktemp; do gate_require_tool "$t"; done
  GATE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  GATE_BASE_REF="${GATE_BASE_REF:-origin/main}"
  GATE_FIXTURE_MODE=0
  GATE_DIR="${GATE_DIR:-scripts}"; GATE_DIR="${GATE_DIR%/}"
  GATE_REGISTRY="${GATE_REGISTRY:-docs/GATES.md}"
  GATE_PITFALLS="${GATE_PITFALLS:-docs/PITFALLS.md}"
  GATE_TODAY="${GATE_TODAY:-$(date +%F)}"
  # Đếm vi phạm qua FILE, không qua biến: gate_violation hay được gọi trong subshell của pipeline
  # (| while read) và biến đếm ở đó không về được tiến trình cha (án lệ nội bộ: 7 cổng in vi phạm mà vẫn PASS).
  GATE_VFILE="$(mktemp)" || gate_broken "không tạo được file tạm"
  trap 'rm -f "$GATE_VFILE"' EXIT
  while [ $# -gt 0 ]; do
    case "$1" in
      --root) [ $# -ge 2 ] || gate_broken "--root thiếu giá trị"; GATE_ROOT="$2"; GATE_FIXTURE_MODE=1; shift 2 ;;
      --base) [ $# -ge 2 ] || gate_broken "--base thiếu giá trị"; GATE_BASE_REF="$2"; shift 2 ;;
      --no-color) shift ;;
      -h|--help) echo "usage: $0 [--root DIR] [--base REF] [--no-color]"; exit 0 ;;
      *) gate_broken "tham số lạ: $1" ;;
    esac
  done
  [ -d "$GATE_ROOT" ] || gate_broken "thư mục gốc không tồn tại: $GATE_ROOT"
  cd "$GATE_ROOT" || gate_broken "không vào được $GATE_ROOT"
  if [ "$GATE_FIXTURE_MODE" = 0 ]; then
    gate_require_tool git
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || gate_broken "$GATE_ROOT không phải repo git (chạy trong repo, hoặc dùng --root cho fixture)"
  fi
}

gate_repo_mode() { [ "$GATE_FIXTURE_MODE" = 0 ]; }

# Danh sách file cần quét (tương đối GATE_ROOT). Loại thư mục build và fixture cổng
# (fixture là vi phạm CỐ Ý — chỉ test-gates.sh quét).
gate_files() {
  if gate_repo_mode; then
    git ls-files --cached --others --exclude-standard | grep -v "^$GATE_DIR/fixtures/" | LC_ALL=C sort -u
  else
    find . -type f \
      -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/target/*' \
      -not -path '*/.next/*' -not -path '*/dist/*' -not -path '*/.turbo/*' \
      | sed 's|^\./||' | grep -v "^$GATE_DIR/fixtures/" | LC_ALL=C sort
  fi
}

# Tên các cổng riêng của repo: $GATE_DIR/check-<tên>.sh → <tên>
gate_local_gates() {
  local f n
  for f in "$GATE_DIR"/check-*.sh; do
    [ -f "$f" ] || continue
    n="${f##*/check-}"; printf '%s\n' "${n%.sh}"
  done | LC_ALL=C sort
}

# Đọc tệp văn bản bỏ CR (máy Windows autocrlf=true đưa CRLF ra cây làm việc).
gate_cat() { tr -d '\r' < "$1"; }

# DD/MM/YYYY hoặc YYYY-MM-DD → số ngày kể từ epoch; in rỗng nếu không đọc được.
gate_days() {
  local s="$1" iso
  case "$s" in
    [0-9]*/[0-9]*/[0-9][0-9][0-9][0-9])
      iso="$(printf '%s' "$s" | awk -F/ '{printf "%04d-%02d-%02d", $3, $2, $1}')" ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) iso="$s" ;;
    *) return 0 ;;
  esac
  local sec; sec="$(date -u -d "$iso" +%s 2>/dev/null)" || return 0
  printf '%s\n' $(( sec / 86400 ))
}

gate_violation() {
  printf '%s\n' "$*" >> "$GATE_VFILE"
  printf '  x %s\n' "$*"
}

gate_note() { printf '  - %s\n' "$*"; }

gate_finish() {
  local n
  n="$(wc -l < "$GATE_VFILE" | tr -d ' ')"
  if [ "$n" -eq 0 ]; then
    printf 'GATE %s: PASS\n' "$GATE_NAME"
    exit "$GATE_EXIT_PASS"
  fi
  printf 'GATE %s: FAIL - %d vi phạm (danh sách ở trên)\n' "$GATE_NAME" "$n"
  exit "$GATE_EXIT_FAIL"
}
