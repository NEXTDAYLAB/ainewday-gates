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
# secret-scan chế độ repo — phạm vi lịch sử (06/11/2026): bí mật ở NHÁNH KHÁC không làm đỏ PR; bí mật trong commit của PR (kể cả đã xoá ở commit sau) vẫn đỏ.
if command -v gitleaks >/dev/null 2>&1; then
  ss_repo() { # in ra đường dẫn repo tạm: main sạch · nhánh khac có bí mật · nhánh pr ($1 = co|khong bí mật trong PR, đã xoá ở commit sau)
    local r; r="$(mktemp -d)"; ( cd "$r" && git init -q -b main && git config user.email t@t && git config user.name t
      mkdir docs && echo "# sạch" > docs/a.md && git add . && git commit -qm goc
      git checkout -qb khac && echo "matkhau: GIA-123-KHONG-PHAI-THAT" > docs/b.md && git add . && git commit -qm khac
      git checkout -q main && git checkout -qb pr
      if [ "$1" = co ]; then echo "matkhau: GIA-456-KHONG-PHAI-THAT" > docs/c.md && git add . && git commit -qm lo && git rm -q docs/c.md && git commit -qm xoa; fi
      echo "# pr" > docs/d.md && git add . && git commit -qm pr ) >/dev/null 2>&1; printf '%s' "$r"; }
  ss_case() { # $1 mô tả, $2 co|khong, $3 mã cần, còn lại = env
    local d="$1" k="$2" want="$3" r rc; shift 3; r="$(ss_repo "$k")"; cases=$((cases + 1))
    ( cd "$r" && env "$@" bash "$HERE/check-secret-scan.sh" --base main >/dev/null 2>&1 ); rc=$?; rm -rf "$r"
    if [ "$rc" -eq "$want" ]; then printf 'v %-24s %s: mã %s đúng
' secret-scan "$d" "$rc"; else printf 'x %-24s %s: mã %s, cần %s
' secret-scan "$d" "$rc" "$want"; fail=1; fi; }
  ss_case "bí mật chỉ ở nhánh khác, PR sạch" khong 0 GATE_SECRET_FULL=0
  ss_case "bí mật trong commit PR (đã xoá sau)" co 1 GATE_SECRET_FULL=0
  ss_case "GATE_SECRET_FULL=1 quét mọi nhánh" khong 1 GATE_SECRET_FULL=1
fi
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

# Runner: CHẶN HAY CHỈ BÁO (anh Châu quyết 10/11/2026, handbook CI.md nguyên tắc 2). Bỏ qua mọi cổng (không cần gitleaks).
#   fixtures/run-all/chi-bao: chỉ secret-scan khai N/A; 4 cổng chỉ báo bỏ qua không khai
#     mặc định (chỉ secret-scan chặn)        ⇒ 0 (4 cảnh báo)
#     GATE_STRICT=1 (mọi cổng chặn)          ⇒ 1
#     GATE_BLOCK=ui-vn-conventions           ⇒ 1 (danh sách chặn đổi được)
#   fixtures/run-all/bad + GATE_BLOCK=""     ⇒ 0 (không cổng nào chặn)
rc_case() { # $1 fixture, $2 mô tả, $3 mã cần, còn lại = env
  local fx="$1" d="$2" want="$3" out rc; shift 3; cases=$((cases + 1))
  out="$(cd "$HERE/fixtures/run-all/$fx" && env GATE_SKIP="$all" "$@" bash "$HERE/run-all.sh" 2>&1)"; rc=$?
  if [ "$rc" -eq "$want" ]; then printf 'v %-24s %s: mã %s đúng\n' run-all "$d" "$rc"
  else printf 'x %-24s %s: mã %s, cần %s\n%s\n' run-all "$d" "$rc" "$want" "$out"; fail=1; fi
}
rc_case chi-bao "cổng chỉ báo bỏ qua không khai ⇒ xanh" 0
rc_case chi-bao "GATE_STRICT=1 ⇒ mọi cổng chặn" 1 GATE_STRICT=1
rc_case chi-bao "GATE_BLOCK đổi danh sách chặn" 1 GATE_BLOCK=ui-vn-conventions
rc_case bad "GATE_BLOCK rỗng ⇒ không cổng nào chặn" 0 GATE_BLOCK=

echo "test-gates: $total cổng, $cases ca; $([ $fail = 0 ] && echo 'TẤT CẢ đúng (biết đỏ, biết xanh, biết BROKEN)' || echo 'CÓ CA SAI')"
exit $fail
