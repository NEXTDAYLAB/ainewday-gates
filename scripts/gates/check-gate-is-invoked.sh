#!/usr/bin/env bash
# gate-is-invoked (lock) — mắt xích script ↔ NƠI GỌI (chuẩn GATES nội bộ §2 #3).
#  1. Mọi cổng riêng $GATE_DIR/check-<tên>.sh có tên trong một runner (runner cổng nhanh, Makefile, workflow CI).
#  2. Workflow CI không bọc bước bằng `if: hashFiles(...)` — điều kiện ấy làm cổng tự tắt khi thiếu tệp,
#     tức "không chạy" thành "xanh" (LUAT §5 L1). Ngoại lệ có lý do: ghi `# allow-hashfiles: <lý do>` cùng dòng.
#
# VÌ SAO (án lệ nội bộ, đo 10/09/2026): sáu cổng viết xong, có fixture, có dòng trong sổ, được test-gates
# chứng minh biết đỏ — mà không runner nào gọi. Chúng chưa bao giờ soi một dòng mã thật nào.
# Khái quát từ một dự án nội bộ check-cong-duoc-goi.sh.
#
# Runner: $GATE_RUNNERS (danh sách glob, cách nhau bởi dấu cách). Mặc định:
#   $GATE_DIR/gates-quick.sh $GATE_DIR/run-all.sh Makefile .github/workflows/*.yml .github/workflows/*.yaml package.json
# Khớp khi: tên cổng đứng MỘT MÌNH trên một dòng (danh sách kiểu gates-quick.sh), hoặc `check-<tên>` nằm
# trong một dòng không phải chú thích, hoặc runner chạy vòng lặp `$GATE_DIR/check-*.sh` (gọi tất cả).
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
gate_init "gate-is-invoked" "$@"

runners_glob="${GATE_RUNNERS:-$GATE_DIR/gates-quick.sh $GATE_DIR/run-all.sh Makefile .github/workflows/*.yml .github/workflows/*.yaml package.json}"
content="$(mktemp)"; trap 'rm -f "$GATE_VFILE" "$content"' EXIT
has_runner=0
for r in $runners_glob; do
  [ -f "$r" ] || continue
  has_runner=1
  # Bỏ dòng chú thích (# …) — tên nằm trong chú thích không phải là được gọi.
  gate_cat "$r" | grep -vE '^[[:space:]]*#' >> "$content"
done

local_gates="$(gate_local_gates)"
count=0
if [ -n "$local_gates" ]; then
  [ "$has_runner" = 1 ] || gate_violation "có cổng riêng trong $GATE_DIR/ mà không thấy runner nào ($runners_glob)"
  if grep -qF "$GATE_DIR/check-*.sh" "$content"; then
    gate_note "runner chạy vòng lặp $GATE_DIR/check-*.sh — mọi cổng được gọi"
  else
    for name in $local_gates; do
      count=$((count + 1))
      if sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$content" | grep -qxF "$name"; then continue; fi
      grep -qE "check-$name([^a-z0-9-]|\$)" "$content" && continue
      gate_violation "$GATE_DIR/check-$name.sh — không runner nào gọi; cổng này không bao giờ soi mã thật"
    done
  fi
fi

# 2. if: hashFiles(...) trong workflow
for wf in .github/workflows/*.yml .github/workflows/*.yaml; do
  [ -f "$wf" ] || continue
  gate_cat "$wf" | grep -nE '^[[:space:]]*(-[[:space:]]*)?if:.*hashFiles[[:space:]]*\(' | grep -v 'allow-hashfiles:' | while IFS=: read -r line _; do
    gate_violation "$wf:$line — 'if: hashFiles(...)' làm bước tự tắt khi thiếu tệp (không chạy ⇒ xanh giả); bỏ điều kiện, hoặc ghi '# allow-hashfiles: <lý do>'"
  done
done

gate_note "$count cổng riêng đã đối chiếu runner"
gate_finish
