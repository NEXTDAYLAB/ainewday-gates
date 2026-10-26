#!/usr/bin/env bash
# tech-stack-approved (lock) — repo đã có mã ứng dụng ⇒ tech stack đã được PO duyệt hoặc miễn trình.
# chuẩn GATES nội bộ §5A · LUAT §5 L8 · căn cứ BH-007, BH-033 (sự cố nội bộ).
#
#  Có mã ứng dụng = có package.json / Cargo.toml / pyproject.toml / go.mod ở bất kỳ đâu NGOÀI docs/ và .github/
#                   (.github/ chứa công cụ CI như .github/lint/package.json — không phải ứng dụng).
#  Khi đó:  docs/decisions/ADR-000* phải có dòng khớp /(Duyệt|Miễn trình):\**\s*PO/ (cùng regex với
#           script xuất bản trình tech stack) và dòng ấy không còn chỗ giữ chỗ `<ngày>`;
#           nếu là "Duyệt" (không miễn trình) thì docs/decisions/tech-stack.html phải tồn tại.
# Giới hạn (ghi trong sổ): cổng đọc CHỮ, không biết ai gõ dòng ấy. Lớp chặn "agent tự ghi duyệt" là
# review PR có tệp ADR-000 (CODEOWNERS) — cổng này chặn ca phổ biến hơn: chưa trình mà đã code.
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
gate_init "tech-stack-approved" "$@"

manifests="$(gate_files | grep -E '(^|/)(package\.json|Cargo\.toml|pyproject\.toml|go\.mod)$' \
  | grep -vE '^(docs|\.github)/' | grep -v '/node_modules/')"
if [ -z "$manifests" ]; then
  gate_note "chưa có mã ứng dụng (không thấy package.json/Cargo.toml/pyproject.toml/go.mod ngoài docs/, .github/)"
  gate_finish
fi
gate_note "mã ứng dụng: $(printf '%s\n' "$manifests" | head -3 | tr '\n' ' ')"

adr=""
for f in docs/decisions/*; do
  [ -f "$f" ] || continue
  case "${f##*/}" in [Aa][Dd][Rr]-000*) adr="$f"; break ;; esac
done
if [ -z "$adr" ]; then
  gate_violation "có mã ứng dụng mà không có docs/decisions/ADR-000* (quyết định tech stack) — trình PO bằng skill ainewday-tech-stack"
  gate_finish
fi

po="${GATE_PO_NAME:-}"   # tên người duyệt (workflow input po-name); trống ⇒ chấp nhận mọi tên đã điền
if [ -n "$po" ]; then pat="(Duyệt|Miễn trình):\**[[:space:]]*$po"; else pat='(Duyệt|Miễn trình):\**[[:space:]]*[^[:space:]<]'; fi
ok_lines="$(gate_cat "$adr" | grep -E "$pat" | grep -v '<ngày>')"
if [ -z "$ok_lines" ]; then
  gate_violation "$adr — chưa có dòng 'Duyệt: PO <ngày>' hoặc 'Miễn trình: PO <ngày>'; agent KHÔNG tự ghi duyệt"
elif ! printf '%s\n' "$ok_lines" | grep -q 'Miễn trình' && [ ! -f docs/decisions/tech-stack.html ]; then
  gate_violation "$adr ghi Duyệt nhưng thiếu docs/decisions/tech-stack.html (bản trình anh đã duyệt)"
else
  gate_note "$adr: $(printf '%s\n' "$ok_lines" | head -1 | sed 's/^[[:space:]>*-]*//')"
fi
gate_finish
