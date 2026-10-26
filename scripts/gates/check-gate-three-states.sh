#!/usr/bin/env bash
# gate-three-states (lock) — mọi cổng riêng của repo ($GATE_DIR/check-*.sh) phải dùng thư viện gate.sh
# (gate_init + gate_finish) để có đủ ba trạng thái đạt / vi phạm / BROKEN (chuẩn GATES nội bộ §1).
# Khái quát từ một dự án nội bộ check-gate-three-states.sh.
# Giới hạn (camera một phần): kiểm script CÓ dùng thư viện, không chạy thử từng script.
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
gate_init "gate-three-states" "$@"
count=0
for s in "$GATE_DIR"/check-*.sh; do
  [ -f "$s" ] || continue
  count=$((count + 1))
  content="$(gate_cat "$s")"
  printf '%s\n' "$content" | grep -Eq '^[^#]*(source|\.)[[:space:]].*gate\.sh' || gate_violation "$s — không source thư viện gate.sh"
  printf '%s\n' "$content" | grep -Eq '^[^#]*gate_init'   || gate_violation "$s — thiếu gate_init"
  printf '%s\n' "$content" | grep -Eq '^[^#]*gate_finish' || gate_violation "$s — thiếu gate_finish"
  # "|| true" / "exit 0" cứng ở cuối script là cách quy BROKEN về xanh.
  printf '%s\n' "$content" | grep -nE '^[[:space:]]*gate_finish[[:space:]]*\|\|[[:space:]]*(true|exit 0|:)' | while IFS=: read -r line _; do
    gate_violation "$s:$line — gate_finish bị nuốt mã thoát (|| true / || exit 0)"
  done
done
gate_note "$count cổng riêng trong $GATE_DIR/"
gate_finish
