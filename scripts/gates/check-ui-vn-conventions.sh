#!/usr/bin/env bash
# ui-vn-conventions (lock) — giao diện theo Quy ước giao diện người dùng VN (handbook standards/UI_VN.md).
# LUAT §5 L11 · căn cứ BH-048 (EH 24–28/10/2026: mã máy, số không dấu chấm, ngày kiểu Mỹ lọt tới PO khi UAT — sửa 3 lần).
#
# Quét tệp giao diện (.tsx .jsx .vue .svelte .astro .html), bỏ test/e2e/fixture/build. Bắt những gì ĐỌC ĐƯỢC từ mã nguồn:
#   Luật 1  ô số gốc của trình duyệt: type="number", inputMode/inputmode numeric|decimal  ⇒ dùng ô số chung (dấu chấm hàng nghìn)
#   Luật 2  mã máy trong chữ hiện ra: chữ SNAKE_CASE viết hoa giữa thẻ (>PENDING_USE<), {x.id} {x.uuid} {x.key} {err.code}
#           {err.name} {err.stack} hiện giữa thẻ
#   Luật 3  giới hạn của máy: MAX_SAFE_INTEGER, MAX_VALUE, 9007199254740991 (mọi cách ngăn), 2147483647
#   Luật 4  ô ngày gốc: type="date|datetime-local|month|week|time"; toLocaleDateString()/toLocaleString() không tham số hoặc 'en-…';
#           chuỗi định dạng kiểu Mỹ MM/DD/YYYY
# Luật 5 (sửa nhanh trên dòng) KHÔNG đọc được từ mã nguồn ⇒ thành phần chung + câu hỏi Reviewer (UI_VN.md §5).
#
# Ngoại lệ có chủ đích:
#   - Tệp THÀNH PHẦN CHUNG mang dấu `ui-vn: thanh-phan-chung` (chú thích bất kỳ) ⇒ bỏ luật 1 và 4 cho tệp đó (nó chính là nơi bọc ô gốc).
#   - Một dòng mang `ui-vn-ok: <lý do>` (lý do không rỗng) ⇒ bỏ dòng đó, in ra để Reviewer thấy. `ui-vn-ok:` trống lý do ⇒ vi phạm.
#   - Tệp `.ui-vn-ignore` ở gốc repo: màn kỹ thuật (công cụ dev) — mỗi dòng `<biểu thức đường dẫn>  # <lý do>`; thiếu lý do ⇒ vi phạm.
# Giới hạn (ghi trong sổ): đọc chữ trong mã, không chạy giao diện — mã máy lấy từ dữ liệu lúc chạy (key tham số từ API) chỉ bắt được bằng
# bài e2e quét chữ trên màn (handbook templates/ui-vn/machine-codes.ts).
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
gate_init "ui-vn-conventions" "$@"
gate_require_tool xargs; gate_require_tool comm

files="$(gate_files | grep -E '\.(tsx|jsx|vue|svelte|astro|html)$' \
  | grep -vE '(^|/)(node_modules|dist|build|\.next|coverage|vendor|fixtures|__tests__|tests?|e2e)/' \
  | grep -vE '\.(test|spec|stories)\.[a-z]+$')"
# .ui-vn-ignore (gốc repo): màn KỸ THUẬT không dành cho người dùng nghiệp vụ (công cụ dev, bảng điều khiển API…).
# Mỗi dòng: `<biểu thức đường dẫn, grep -E>  # <lý do>` — thiếu lý do ⇒ vi phạm (bỏ qua phải thành văn).
if [ -f .ui-vn-ignore ]; then
  n=0
  while IFS= read -r l; do
    n=$((n + 1)); l="$(printf '%s' "$l" | tr -d '\r')"
    case "$l" in ''|'#'*) continue ;; esac
    pat="$(printf '%s' "${l%%#*}" | sed -E 's/[[:space:]]+$//')"; why="$(printf '%s' "${l#*#}" | sed -E 's/^[[:space:]]+//')"
    if [ "$pat" = "$l" ] || [ -z "$why" ] || [ -z "$pat" ]; then gate_violation ".ui-vn-ignore:$n — thiếu '# lý do': $l"; continue; fi
    files="$(printf '%s\n' "$files" | grep -vE -- "$pat")"
    gate_note "bỏ qua theo .ui-vn-ignore: $pat — $why"
  done < .ui-vn-ignore
fi
if [ -z "$files" ]; then
  gate_note "không có tệp giao diện (.tsx .jsx .vue .svelte .astro .html ngoài test/build)"
  gate_finish
fi
gate_note "quét $(printf '%s\n' "$files" | wc -l | tr -d ' ') tệp giao diện"

# Mỗi luật: nhãn | biểu thức (grep -E) | áp cả tệp thành phần chung? (1 = có)
rules="$(cat <<'EOF'
luật 1 — ô số gốc (không có dấu chấm hàng nghìn); dùng ô số chung|type[[:space:]]*=[[:space:]]*[{]?[[:space:]]*["'`]number["'`]|0
luật 1 — inputMode số tự làm; dùng ô số chung|input[Mm]ode[[:space:]]*=[[:space:]]*[{]?[[:space:]]*["'`](numeric|decimal)["'`]|0
luật 2 — mã máy SNAKE_CASE trong chữ hiện ra; hiện tên tiếng Việt|>([^<>{}]*[^A-Za-z0-9_<>{}])?[A-Z][A-Z0-9]*(_[A-Z0-9]+)+([^A-Za-z0-9_][^<>{}]*)?<|1
luật 2 — hiện id/uuid/key/mã lỗi lên màn; hiện tên hoặc mã nghiệp vụ|(^|[^=$])[{][[:space:]]*[A-Za-z_$][A-Za-z0-9_$.?]*[.](id|uuid|key)[[:space:]]*[}]|1
luật 2 — hiện mã lỗi kỹ thuật lên màn; hiện câu tiếng Việt|(^|[^=$])[{][[:space:]]*(err|error|e|ex)[.?]*[.](code|name|stack)[[:space:]]*[}]|1
luật 3 — giới hạn của máy hiện ra (chỉ hiện giới hạn nghiệp vụ)|(^|[^=$])[{][^{}]*MAX_(SAFE_INTEGER|VALUE)[^{}]*[}][^;]*<|9[., ]?007[., ]?199[., ]?254[., ]?740[., ]?99[12]|2[., ]?147[., ]?483[., ]?647|1
luật 4 — ô ngày/giờ gốc (hiện theo ngôn ngữ máy); dùng ô ngày chung dd/mm/yyyy|type[[:space:]]*=[[:space:]]*[{]?[[:space:]]*["'`](date|datetime-local|month|week|time)["'`]|0
luật 4 — ngày theo ngôn ngữ máy/kiểu Mỹ; dùng hàm định dạng dd/mm/yyyy|toLocale(Date)?String[(][[:space:]]*([)]|["'`]en)|1
luật 4 — chuỗi định dạng ngày kiểu Mỹ|["'`](MM/DD/YYYY|mm/dd/yyyy|MM/dd/yyyy|M/d/yyyy)["'`]|1
EOF
)"

tmp="$(mktemp -d)"; trap 'rm -rf "$GATE_VFILE" "$tmp"' EXIT
printf '%s\n' "$files" > "$tmp/all"
# Tệp thành phần chung (bỏ luật 1, 4 cho tệp đó). Mỗi luật chạy MỘT grep trên cả danh sách (nhanh cả trên Windows).
tr '\n' '\0' < "$tmp/all" | xargs -0 grep -l 'ui-vn: thanh-phan-chung' | LC_ALL=C sort > "$tmp/shared"
LC_ALL=C sort "$tmp/all" | LC_ALL=C comm -23 - "$tmp/shared" > "$tmp/plain"

printf '%s\n' "$rules" | while IFS= read -r rule; do
  [ -n "$rule" ] || continue
  label="${rule%%|*}"; rest="${rule#*|}"; all="${rest##*|}"; re="${rest%|*}"
  list="$tmp/all"; [ "$all" = 0 ] && list="$tmp/plain"
  [ -s "$list" ] || continue
  tr '\n' '\0' < "$list" | xargs -0 grep -nHE -- "$re" 2>/dev/null | tr -d '\r' | while IFS= read -r hit; do
    f="${hit%%:*}"; rest2="${hit#*:}"; line="${rest2%%:*}"; text="${rest2#*:}"
    case "$text" in
      *'ui-vn-ok:'*)  # có lý do ⇒ ghi để Reviewer soát; trống lý do ⇒ khối dưới báo (một lần)
        reason="$(printf '%s' "$text" | sed -E 's/.*ui-vn-ok:[[:space:]]*//; s/[[:space:]]*(\*\/|-->|\}).*$//')"
        [ -n "$reason" ] && printf '%s:%s — %s\n' "$f" "$line" "$reason" >> "$tmp/ok"
        continue ;;
    esac
    gate_violation "$f:$line — $label: $(printf '%s' "$text" | sed -E 's/^[[:space:]]+//' | cut -c1-120)"
  done
done
# ui-vn-ok: trống lý do ở BẤT KỲ dòng nào ⇒ vi phạm — ngoại lệ phải thành văn.
tr '\n' '\0' < "$tmp/all" | xargs -0 grep -nHE 'ui-vn-ok:[[:space:]]*($|\*/|-->|[}])' 2>/dev/null | while IFS= read -r hit; do
  f="${hit%%:*}"; rest2="${hit#*:}"
  gate_violation "$f:${rest2%%:*} — ui-vn-ok: thiếu lý do"
done
if [ -s "$tmp/ok" ]; then
  gate_note "ngoại lệ có lý do (ui-vn-ok), Reviewer soát:"
  sort -u "$tmp/ok" | while IFS= read -r l; do gate_note "  $l"; done
fi
gate_finish
