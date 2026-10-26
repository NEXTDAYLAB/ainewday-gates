#!/usr/bin/env bash
# gate-registry-in-sync (lock) — sổ cổng ($GATE_REGISTRY, mặc định docs/GATES.md) ↔ cổng khớp hai chiều.
#  Chiều 1: mọi cổng riêng $GATE_DIR/check-<tên>.sh VÀ mọi cổng của chuỗi gate-chain ($GATE_CHAIN_GATES,
#           run-all.sh đặt) có dòng `| \`<tên>\` |` trong sổ.
#  Chiều 2: dòng đánh ✅ ở cột cuối phải có script (riêng hoặc của chuỗi), trừ dòng tự khai nơi chạy:
#           "test tích hợp", tên kết thúc "-test", "chạy trong `<công cụ>`", "đích make".
# Khái quát từ một dự án nội bộ check-gate-registry-in-sync.sh.
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
gate_init "gate-registry-in-sync" "$@"
reg="$GATE_REGISTRY"
if [ ! -f "$reg" ]; then
  gate_violation "không có sổ cổng $reg — tạo theo ainewday-handbook templates/GATES_REGISTRY_TEMPLATE.md"
  gate_finish
fi
reg_text="$(mktemp)"; trap 'rm -f "$GATE_VFILE" "$reg_text"' EXIT
gate_cat "$reg" > "$reg_text"

chain="${GATE_CHAIN_GATES:-}"
local_gates="$(gate_local_gates)"
for name in $(printf '%s\n%s\n' "$local_gates" "$chain" | tr ' ' '\n' | grep -v '^$' | LC_ALL=C sort -u); do
  grep -qF "| \`$name\`" "$reg_text" || gate_violation "$reg — thiếu dòng \`$name\` (cổng có chạy mà sổ không khai)"
done

grep -E '^\| `[a-z0-9-]+` \|.*\| ✅[^|]*\|[[:space:]]*$' "$reg_text" | while IFS= read -r row; do
  name="$(printf '%s' "$row" | sed -E 's/^\| `([a-z0-9-]+)`.*/\1/')"
  case "$row" in *"test tích hợp"*|*"-test\`"*|*"chạy trong \`"*|*"đích make"*) continue ;; esac
  [ -f "$GATE_DIR/check-$name.sh" ] && continue
  printf '%s\n' $chain | grep -qxF "$name" && continue
  gate_violation "$reg — \`$name\` đánh ✅ nhưng không có $GATE_DIR/check-$name.sh, cũng không thuộc chuỗi gate-chain"
done
gate_finish
