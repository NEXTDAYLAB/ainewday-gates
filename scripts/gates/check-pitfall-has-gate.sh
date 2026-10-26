#!/usr/bin/env bash
# pitfall-has-gate (camera) — mỗi mục án lệ `## <MÃ>-<số>` trong sổ $GATE_PITFALLS (mặc định docs/PITFALLS.md)
# phải có dòng **Cổng đóng bẫy:** (tên cổng · ràng buộc · "⏳ hạn …" · hoặc "không thành luật — vì …").
# Hạn 7 ngày của mục còn ⏳ do cổng gate-not-overdue canh (LUAT §2.2–2.3).
# Khái quát từ một dự án nội bộ check-pitfall-has-gate.sh: nhận mọi tiền tố (T-, P-, …), bỏ qua khối mã ``` (mục mẫu).
# Camera: chỉ kiểm có dòng, không kiểm cổng ghi trong dòng có thật.
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
gate_init "pitfall-has-gate" "$@"
f="$GATE_PITFALLS"
if [ ! -f "$f" ]; then
  gate_violation "không có sổ án lệ $f — tạo theo ainewday-handbook templates/PITFALLS_TEMPLATE.md (hoặc khai N/A + lý do trong sổ cổng)"
  gate_finish
fi
gate_cat "$f" | awk '
  /^[[:space:]]*```/ { fence = !fence; next }
  fence { next }
  /^## [A-Z]+-[0-9]+/ { if (sec != "" && !has) print sec; sec = $0; has = 0; n++; next }
  /^## / { if (sec != "" && !has) print sec; sec = ""; has = 0; next }
  /\*\*Cổng đóng bẫy:?\*\*/ { has = 1 }
  END { if (sec != "" && !has) print sec; print "#COUNT " n + 0 }
' > "$GATE_VFILE.p"
count="$(sed -n 's/^#COUNT //p' "$GATE_VFILE.p")"
grep -v '^#COUNT ' "$GATE_VFILE.p" | while IFS= read -r sec; do
  gate_violation "$f — mục \"${sec#\#\# }\" không có dòng **Cổng đóng bẫy:**"
done
rm -f "$GATE_VFILE.p"
gate_note "$count mục án lệ"
gate_finish
