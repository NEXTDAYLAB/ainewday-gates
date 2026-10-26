#!/usr/bin/env bash
# doc-ids-unique (lock) — số hiệu sổ đánh số không TRÙNG, không NHẢY (chuẩn GATES nội bộ §2 #5).
#  - ADR: tệp trong docs/decisions/ tên dạng `0007-…`, `ADR-007-…`, `ADR007_…` — lấy số đầu tên.
#  - Án lệ: tiêu đề `## <MÃ>-<số>` trong $GATE_PITFALLS (ngoài khối ```), xét riêng từng tiền tố.
# Số bỏ đi thì giữ tệp/mục "đã huỷ" mang số đó (không đánh lại số — người khác đang dẫn chiếu).
# Không tin script cấp số: chính một dự án nội bộ có mục PITFALLS trùng số dù đã có script (GATES §2).
# Khái quát từ một dự án nội bộ check-adr-number-unique.sh (chỉ bắt trùng ADR) — thêm nhảy số và PITFALLS.
# Chưa phủ: thư mục migration (mỗi stack một kiểu tên — cổng migration-immutable của gói stack lo).
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
gate_init "doc-ids-unique" "$@"

# check_seq <nhãn> : đọc "số<TAB>nguồn" từ stdin, báo trùng và nhảy.
check_seq() {
  local label="$1" data nums n prev
  data="$(cat)"
  [ -n "$data" ] || return 0
  printf '%s\n' "$data" | awk -F'\t' '{c[$1+0]++; s[$1+0] = s[$1+0] " " $2} END {for (k in c) if (c[k] > 1) print k "\t" s[k]}' \
    | LC_ALL=C sort -n | while IFS="$(printf '\t')" read -r n where; do
        gate_violation "$label — số $n dùng nhiều lần:$where"
      done
  nums="$(printf '%s\n' "$data" | cut -f1 | awk '{print $1+0}' | LC_ALL=C sort -n -u)"
  prev=""
  for n in $nums; do
    if [ -n "$prev" ] && [ "$n" -gt $((prev + 1)) ]; then
      gate_violation "$label — nhảy số: sau $prev là $n (thiếu $((prev + 1))$([ "$n" -gt $((prev + 2)) ] && echo "…$((n - 1))"))"
    fi
    prev="$n"
  done
  gate_note "$label: $(printf '%s\n' "$nums" | grep -c .) số, từ $(printf '%s\n' "$nums" | head -1) tới $prev"
}

found=0
if [ -d docs/decisions ]; then
  found=1
  for f in docs/decisions/*; do
    [ -f "$f" ] || continue
    b="${f##*/}"
    n="$(printf '%s' "$b" | sed -n 's/^\([Aa][Dd][Rr][-_]\{0,1\}\)\{0,1\}\([0-9]\{3,4\}\)[-_. ].*/\2/p')"
    [ -n "$n" ] && printf '%s\t%s\n' "$n" "$b"
  done | check_seq "docs/decisions (ADR)"
fi

if [ -f "$GATE_PITFALLS" ]; then
  found=1
  gate_cat "$GATE_PITFALLS" | awk '
    /^[[:space:]]*```/ { fence = !fence; next }
    fence { next }
    /^## [A-Z]+-[0-9]+/ { s = substr($0, 4); p = s; sub(/-.*/, "", p); n = s; sub(/^[A-Z]+-/, "", n); sub(/[^0-9].*/, "", n); print p "\t" n "\t" NR }
  ' > "$GATE_VFILE.p"
  for prefix in $(cut -f1 "$GATE_VFILE.p" | LC_ALL=C sort -u); do
    awk -F'\t' -v p="$prefix" '$1 == p {print $2 "\t" "dòng " $3}' "$GATE_VFILE.p" | check_seq "$GATE_PITFALLS ($prefix-)"
  done
  rm -f "$GATE_VFILE.p"
fi
[ "$found" = 1 ] || gate_note "không có docs/decisions/ và $GATE_PITFALLS — không có sổ đánh số để kiểm"
gate_finish
