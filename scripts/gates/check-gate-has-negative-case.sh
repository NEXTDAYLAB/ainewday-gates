#!/usr/bin/env bash
# gate-has-negative-case (lock) — mỗi cổng riêng có ca kiểm âm: $GATE_DIR/fixtures/<tên>/ tồn tại và có tệp.
# Chế độ repo: đếm bằng `git ls-files` để tệp bị .gitignore nuốt (có ở máy, không có trên CI) lộ ngay
# ở máy (án lệ nội bộ). Khái quát từ một dự án nội bộ check-gate-has-negative-case.sh.
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
gate_init "gate-has-negative-case" "$@"
count=0
for name in $(gate_local_gates); do
  count=$((count + 1))
  fx="$GATE_DIR/fixtures/$name"
  if [ ! -d "$fx" ]; then gate_violation "$GATE_DIR/check-$name.sh — không có ca kiểm âm $fx/"; continue; fi
  if gate_repo_mode; then
    n="$(git ls-files --cached --others --exclude-standard -- "$fx" | wc -l | tr -d ' ')"
    [ "$n" -gt 0 ] || gate_violation "$GATE_DIR/check-$name.sh — $fx/ không có tệp nào git theo dõi (bị .gitignore?)"
  else
    [ -n "$(ls -A "$fx")" ] || gate_violation "$GATE_DIR/check-$name.sh — $fx/ rỗng"
  fi
done
gate_note "$count cổng riêng đã đối chiếu ca kiểm âm"
gate_finish
