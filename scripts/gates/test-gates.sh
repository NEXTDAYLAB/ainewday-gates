#!/usr/bin/env bash
# Chứng minh MỖI cổng dùng chung biết ĐỎ và biết XANH (chuẩn GATES nội bộ §2 #2 — ca kiểm âm).
#
# Mỗi cổng có scripts/gates/fixtures/<tên>/ gồm:
#   bad/  + good/              repo giả (chế độ --root, không git): bad phải thoát 1, good phải thoát 0
#   setup-bad.sh / setup-good.sh   (thay cho bad/ good/ khi cổng cần git) in ra đường dẫn một repo git tạm;
#                                cổng chạy trong repo đó ở chế độ repo
#   env    (tuỳ chọn)          dòng KEY=VALUE xuất cho cả hai ca (vd GATE_TODAY để ca hạn chót không trôi theo ngày)
#   args   (tuỳ chọn)          tham số thêm cho cả hai ca (vd --base base)
# Rồi các ca BROKEN: thư mục gốc không tồn tại ⇒ 2 (mọi cổng); thiếu gitleaks ⇒ secret-scan 2;
# và runner: bỏ qua cổng không khai N/A ⇒ 1, có khai ⇒ 0.
set -u
cd "$(dirname "$0")" || exit 2
HERE="$(pwd)"
fail=0; total=0; cases=0

run_case() { # $1 tên cổng, $2 bad|good, $3 mã cần
  local g="$1" kind="$2" want="$3" fx="$HERE/fixtures/$1" root out rc extra=""
  [ -f "$fx/args" ] && extra="$(tr -d '\r' < "$fx/args")"
  cases=$((cases + 1))
  if [ -f "$fx/setup-$kind.sh" ]; then
    root="$(bash "$fx/setup-$kind.sh")" || { printf 'x %-24s %-4s setup-%s.sh lỗi\n' "$g" "$kind" "$kind"; fail=1; return; }
    # shellcheck disable=SC2086
    out="$(cd "$root" && env $(cat "$fx/env" 2>/dev/null | tr -d '\r') bash "$HERE/check-$g.sh" $extra 2>&1)"; rc=$?
    rm -rf "$root"
  elif [ -d "$fx/$kind" ]; then
    # shellcheck disable=SC2086
    out="$(env $(cat "$fx/env" 2>/dev/null | tr -d '\r') bash "$HERE/check-$g.sh" --root "$fx/$kind" $extra 2>&1)"; rc=$?
  else
    printf 'x %-24s %-4s KHÔNG CÓ ca %s (fixtures/%s/%s hoặc setup-%s.sh)\n' "$g" "$kind" "$kind" "$g" "$kind" "$kind"; fail=1; return
  fi
  if [ "$rc" -eq "$want" ]; then
    printf 'v %-24s %-4s mã %s đúng (%s)\n' "$g" "$kind" "$rc" "$([ "$want" = 1 ] && echo đỏ || echo xanh)"
  else
    printf 'x %-24s %-4s mã %s, cần %s\n%s\n' "$g" "$kind" "$rc" "$want" "$out" | sed '3,$s/^/      /'; fail=1
  fi
}

for s in "$HERE"/check-*.sh; do
  g="${s##*/check-}"; g="${g%.sh}"
  total=$((total + 1))
  [ -d "$HERE/fixtures/$g" ] || { printf 'x %-24s KHÔNG CÓ fixtures/%s/\n' "$g" "$g"; fail=1; continue; }
  run_case "$g" bad 1
  run_case "$g" good 0
  # BROKEN: thư mục gốc không tồn tại ⇒ 2, không bao giờ 0
  cases=$((cases + 1))
  out="$(bash "$s" --root "$HERE/fixtures/__khong-ton-tai__" 2>&1)"; rc=$?
  if [ "$rc" -eq 2 ]; then printf 'v %-24s gốc vắng mặt ⇒ BROKEN (2)\n' "$g"
  else printf 'x %-24s gốc vắng mặt mà mã %s (cần 2)\n%s\n' "$g" "$rc" "$out"; fail=1; fi
done

# BROKEN: thiếu công cụ ngoài (gitleaks) ⇒ 2. PATH tối thiểu chỉ có công cụ lõi, KHÔNG có gitleaks.
minpath="$(mktemp -d)"
for c in bash dirname basename tail head cat grep sed awk gawk mawk find sort uniq wc cut tr ls rm mktemp git printf env true false date pwd; do
  p="$(command -v "$c" 2>/dev/null)" || continue
  ln -s "$p" "$minpath/$c" 2>/dev/null || cp "$p" "$minpath/$c" 2>/dev/null || true
done
# Git Bash (Windows): ln -s thành bản sao .exe, cần DLL msys đi kèm mới chạy được.
for dll in /usr/bin/msys-*.dll; do [ -f "$dll" ] && cp "$dll" "$minpath/" 2>/dev/null; done
cases=$((cases + 1))
out="$(PATH="$minpath" "$BASH" "$HERE/check-secret-scan.sh" --root "$HERE/fixtures/secret-scan/good" 2>&1)"; rc=$?
# Phải BROKEN ĐÚNG LÝ DO (thiếu gitleaks) — không phải vì thiếu công cụ lõi hay thư viện.
if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -q "thiếu công cụ 'gitleaks'"; then printf 'v %-24s thiếu gitleaks ⇒ BROKEN (2), đúng lý do\n' secret-scan
else printf 'x %-24s thiếu gitleaks mà mã %s (cần 2)\n%s\n' secret-scan "$rc" "$out"; fail=1; fi
rm -rf "$minpath"

# Runner: GATE_SKIP mọi cổng — sổ không khai N/A ⇒ 1; có khai ⇒ 0.
all="$(sed -n '/^GATES="/,/^"/p' "$HERE/run-all.sh" | grep -E '^[a-z0-9-]+$' | tr '\n' ' ')"
for kind in bad good; do
  want=$([ "$kind" = bad ] && echo 1 || echo 0); cases=$((cases + 1))
  out="$(cd "$HERE/fixtures/run-all/$kind" && GATE_SKIP="$all" bash "$HERE/run-all.sh" 2>&1)"; rc=$?
  if [ "$rc" -eq "$want" ]; then printf 'v %-24s %-4s mã %s đúng\n' run-all "$kind" "$rc"
  else printf 'x %-24s %-4s mã %s, cần %s\n%s\n' run-all "$kind" "$rc" "$want" "$out"; fail=1; fi
done

echo "test-gates: $total cổng, $cases ca; $([ $fail = 0 ] && echo 'TẤT CẢ đúng (biết đỏ, biết xanh, biết BROKEN)' || echo 'CÓ CA SAI')"
exit $fail
