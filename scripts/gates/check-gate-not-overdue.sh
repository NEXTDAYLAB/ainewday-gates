#!/usr/bin/env bash
# gate-not-overdue (lock) — mắt xích sổ ↔ THỜI HẠN (chuẩn GATES nội bộ §2 #4, LUAT §2.2–2.3).
#
# A. Sổ cổng ($GATE_REGISTRY): dòng ☐/🟡 mà cột "Bật ở" ≤ "Đợt hiện tại" ⇒ đỏ.
#    - Đầu sổ khai `**Đợt hiện tại:** \`<nhãn>\``; tuỳ chọn `**Thứ tự đợt:** S0-D1, S0-D2, M1, …` để so nhãn.
#    - "Bật ở" là ngày DD/MM/YYYY (so với hôm nay) hoặc nhãn đợt. Không có "Thứ tự đợt" thì nhãn chỉ so BẰNG
#      với đợt hiện tại (giới hạn ghi trong sổ — khai thứ tự để cổng so được ≤).
#    - Thoát duy nhất: dòng ở bảng "Gia hạn" (cột "Hạn mới") có `PO-approved`, hạn mới chưa tới.
#      Gia hạn quá 2 lần cho cùng một cổng ⇒ đỏ (trình PO quyết dựng hay bỏ).
# B. Sổ án lệ ($GATE_PITFALLS): mục `## <MÃ>-<số> … (DD/MM/YYYY)` chưa đóng (không có dòng **Cổng đóng bẫy:**,
#    hoặc dòng ấy còn ⏳) quá 7 ngày ⇒ đỏ. Thoát: dòng Cổng đóng bẫy có `PO-approved` + `hạn DD/MM/YYYY` chưa tới.
#    "không thành luật — vì …" là một cách đóng hợp lệ (LUAT §2.4).
# In bảng sức khoẻ cổng (METRICS).
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
gate_init "gate-not-overdue" "$@"
today="$(gate_days "$GATE_TODAY")"
[ -n "$today" ] || gate_broken "không đọc được ngày hôm nay '$GATE_TODAY'"
tmp="$(mktemp)"; trap 'rm -f "$GATE_VFILE" "$tmp"' EXIT

# ---------- A. Sổ cổng ----------
reg="$GATE_REGISTRY"
total=0; n_ok=0; n_todo=0; n_partial=0; n_overdue=0; n_ext=0
if [ -f "$reg" ]; then
  gate_cat "$reg" | awk -F'|' '
    function trim(s) { gsub(/^[[:space:]*`]+|[[:space:]*`]+$/, "", s); return s }
    /Đợt hiện tại:/ { s = $0; sub(/.*Đợt hiện tại:[*[:space:]]*/, "", s); sub(/<!--.*/, "", s); split(s, a, "`"); v = (a[2] != "" ? a[2] : trim(s)); print "CUR|" trim(v); next }
    /Thứ tự đợt:/   { s = $0; sub(/.*Thứ tự đợt:[*[:space:]]*/, "", s); sub(/<!--.*/, "", s); gsub(/`/, "", s); print "ORDER|" s; next }
    /^\|/ {
      if ($2 !~ /`/ && $0 ~ /Bật ở/) { mode = "gate"; cb = 0; ct = 0
        for (i = 2; i < NF; i++) { h = trim($i); if (h ~ /Bật ở/) cb = i; if (h == "TT" || h ~ /Trạng thái/) ct = i }
        if (ct == 0) ct = NF - 1; next }
      if ($2 !~ /`/ && $0 ~ /Hạn mới/) { mode = "ext"; ch = 0
        for (i = 2; i < NF; i++) if (trim($i) ~ /Hạn mới/) ch = i; next }
      if ($2 !~ /^[[:space:]]*`[a-z0-9-]+`/) next
      name = $2; gsub(/[[:space:]`]/, "", name)
      if (mode == "gate" && cb > 0) print "ROW|" name "|" trim($cb) "|" trim($ct)
      if (mode == "ext" && ch > 0) print "EXT|" name "|" trim($ch) "|" ($0 ~ /PO-approved/ ? "PO" : "-")
      next }
    { mode = "" }
  ' > "$tmp"
  current="$(sed -n 's/^CUR|//p' "$tmp" | head -1)"
  order="$(sed -n 's/^ORDER|//p' "$tmp" | head -1 | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$')"
  [ -n "$current" ] || gate_violation "$reg — thiếu dòng '**Đợt hiện tại:** \`<nhãn>\`' ở đầu sổ (cổng không so được hạn)"

  label_index() { printf '%s\n' "$order" | grep -nxF "$1" | head -1 | cut -d: -f1; }
  # due <hạn>: in "yes" nếu hạn ≤ hôm nay/đợt hiện tại, "no" nếu chưa, "?" nếu không so được.
  due() {
    local d; d="$(gate_days "$1")"
    if [ -n "$d" ]; then [ "$d" -le "$today" ] && echo yes || echo no; return; fi
    [ -n "$current" ] || { echo skip; return; }  # thiếu dòng Đợt hiện tại: đã báo MỘT lần ở trên
    [ "$1" = "$current" ] && { echo yes; return; }
    if [ -n "$order" ]; then
      local a b; a="$(label_index "$1")"; b="$(label_index "$current")"
      if [ -z "$a" ] || [ -z "$b" ]; then echo "?"; return; fi
      [ "$a" -le "$b" ] && echo yes || echo no; return
    fi
    echo no
  }

  while IFS='|' read -r _ name start status; do
    total=$((total + 1))
    case "$status" in
      *✅*) n_ok=$((n_ok + 1)); continue ;;
      *☐*) n_todo=$((n_todo + 1)) ;;
      *🟡*) n_partial=$((n_partial + 1)) ;;
      *) continue ;;  # N/A hoặc trạng thái khác: không tính hạn
    esac
    exts="$(grep -F "EXT|$name|" "$tmp" | grep '|PO$')"
    n_ext_gate="$(printf '%s' "$exts" | grep -c .)"
    [ "$n_ext_gate" -gt 0 ] && n_ext=$((n_ext + 1))
    [ "$n_ext_gate" -gt 2 ] && gate_violation "$reg — \`$name\` đã gia hạn $n_ext_gate lần (> 2) — trình PO quyết dựng hay bỏ"
    r="$(due "$start")"
    if [ "$r" = "?" ]; then gate_violation "$reg — \`$name\`: không so được 'Bật ở = $start' với đợt hiện tại '$current' (thêm vào **Thứ tự đợt:** hoặc ghi ngày DD/MM/YYYY)"; continue; fi
    [ "$r" = yes ] || continue  # no / skip
    last_ext="$(printf '%s\n' "$exts" | grep . | tail -1 | cut -d'|' -f3)"
    if [ -n "$last_ext" ] && [ "$(due "$last_ext")" = no ]; then continue; fi
    n_overdue=$((n_overdue + 1))
    gate_violation "$reg — \`$name\` trạng thái $status, Bật ở $start đã tới (đợt hiện tại $current, hôm nay $GATE_TODAY): QUÁ HẠN (dựng cổng, hoặc gia hạn có PO-approved)"
  done <<EOF
$(grep '^ROW|' "$tmp")
EOF
else
  gate_note "không có sổ cổng $reg — phần A bỏ qua (gate-registry-in-sync báo đỏ)"
fi

# ---------- B. Sổ án lệ ----------
pit="$GATE_PITFALLS"
n_pit_open=0; n_pit_overdue=0
if [ -f "$pit" ]; then
  gate_cat "$pit" | awk '
    /^[[:space:]]*```/ { fence = !fence; next }
    fence { next }
    /^## [A-Z]+-[0-9]+/ { if (sec != "") print "PIT\t" sec "\t" g; sec = $0; g = ""; next }
    /^## / { if (sec != "") print "PIT\t" sec "\t" g; sec = ""; g = ""; next }
    /\*\*Cổng đóng bẫy:?\*\*/ { g = $0; sub(/.*\*\*Cổng đóng bẫy:?\*\*:?[[:space:]]*/, "", g); if (g == "") g = "(trống)" }
    END { if (sec != "") print "PIT\t" sec "\t" g }
  ' > "$tmp"
  while IFS="$(printf '\t')" read -r _ sec gline; do
    [ -n "$sec" ] || continue
    case "$gline" in ""|"(trống)"|*⏳*) ;; *) continue ;; esac
    n_pit_open=$((n_pit_open + 1))
    title="${sec#\#\# }"
    ext="$(printf '%s' "$gline" | sed -n 's/.*hạn[[:space:]]*\([0-9]\{1,2\}\/[0-9]\{1,2\}\/[0-9]\{4\}\).*/\1/p')"
    if [ -n "$ext" ] && printf '%s' "$gline" | grep -q 'PO-approved'; then
      e="$(gate_days "$ext")"; [ -n "$e" ] && [ "$e" -ge "$today" ] && continue
    fi
    d="$(printf '%s' "$sec" | grep -oE '[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}' | head -1)"
    dd="$(gate_days "$d")"
    if [ -z "$dd" ]; then
      gate_violation "$pit — mục \"$title\" chưa đóng bẫy và không có ngày (DD/MM/YYYY) ở tiêu đề — không tính được hạn 7 ngày"
      continue
    fi
    age=$((today - dd))
    if [ "$age" -gt 7 ]; then
      n_pit_overdue=$((n_pit_overdue + 1))
      gate_violation "$pit — mục \"$title\" đã $age ngày chưa có cổng đóng bẫy (> 7 ngày, LUAT §2.2) — dựng cổng, ghi 'không thành luật — vì …', hoặc gia hạn 'PO-approved hạn DD/MM/YYYY'"
    fi
  done <<EOF
$(cat "$tmp")
EOF
else
  gate_note "không có sổ án lệ $pit — phần B bỏ qua (pitfall-has-gate báo đỏ nếu áp dụng)"
fi

echo "  Sức khoẻ cổng: tổng $total · ✅ $n_ok · ☐ $n_todo · 🟡 $n_partial · quá hạn $n_overdue · đang gia hạn $n_ext | án lệ chưa đóng $n_pit_open · quá 7 ngày $n_pit_overdue"
gate_finish
