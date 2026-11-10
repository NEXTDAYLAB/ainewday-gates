#!/usr/bin/env bash
# Runner của chuỗi gate-chain — chạy MỌI cổng dùng chung trên repo hiện tại (thư mục làm việc = gốc repo gọi).
# Workflow .github/workflows/gate-chain.yml gọi ĐÚNG tệp này; trên máy: bash <ainewday-gates>/scripts/gates/run-all.sh
#
# DANH SÁCH DƯỚI ĐÂY LÀ NƠI DUY NHẤT CỔNG DÙNG CHUNG ĐƯỢC CHẠY.
# Anh Châu quyết 03/11/2026 (chat) — dọn luật: gỡ 8 cổng sổ sách khỏi chuỗi (gate-three-states, gate-has-negative-case,
# gate-is-invoked, gate-not-removed, gate-registry-in-sync, gate-not-overdue, doc-ids-unique, pitfall-has-gate).
# Script của chúng vẫn nằm trong thư mục này làm THƯ VIỆN THAM KHẢO (vẫn có ca kiểm âm trong test-gates.sh) — không chạy trong chuỗi.
# Thêm cổng = bỏ một cổng (chống phình, handbook LUAT.md §3) + script check-<tên>.sh + fixtures/<tên>/{bad,good} + một dòng ở đây.
#
# CHẶN HAY CHỈ BÁO — anh Châu quyết 10/11/2026 (chat), handbook standards/CI.md §3 nguyên tắc 2–3:
#   CI chỉ CHẶN lỗi thật (dựng hỏng · sai kiểu · bài kiểm đỏ · lộ bí mật · hỏng dữ liệu · lỗ hổng thư viện mức cao).
#   Trong chuỗi này chỉ `secret-scan` là lỗi thật ⇒ mặc định chỉ nó làm mã thoát khác 0.
#   Cổng còn lại vi phạm / BROKEN / bỏ qua không khai ⇒ in ::warning:: + tóm tắt, KHÔNG làm đỏ.
#   Cổng mới thêm vào chuỗi mặc định CHỈ BÁO; chỉ đưa vào BLOCK_DEFAULT khi đã bắt lỗi sản phẩm thật.
#
# Biến:  GATE_BLOCK="tên1 tên2"   cổng làm đỏ (mặc định BLOCK_DEFAULT). Rỗng = không cổng nào chặn.
#        GATE_STRICT=1             mọi cổng chặn (hành vi trước 10/11/2026) — chỉ khi dự án có bằng chứng.
#        GATE_SKIP="tên1 tên2"     cổng không áp cho repo — mỗi tên nên có dòng trong sổ cổng ghi N/A + lý do;
#                                  thiếu dòng: cổng chặn ⇒ vi phạm, cổng chỉ báo ⇒ cảnh báo.
#        GATE_DIR, GATE_REGISTRY, GATE_PITFALLS, GATE_BASE_REF, GATE_RUNNERS — xem lib/gate.sh và từng cổng.
# Mã thoát: 0 đạt (có thể kèm cảnh báo) · 1 cổng chặn vi phạm · 2 cổng chặn BROKEN (ưu tiên 2).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
GATES="
tech-stack-approved
scripts-lf-executable
secret-scan
ui-vn-conventions
mockup-logo-goc
"
BLOCK_DEFAULT="secret-scan"
GATE_CHAIN_GATES="$(printf '%s' "$GATES" | tr '\n' ' ')"
export GATE_CHAIN_GATES

if [ "${GATE_STRICT:-0}" = 1 ] || [ "${GATE_STRICT:-}" = true ]; then block="$GATE_CHAIN_GATES"
else block="${GATE_BLOCK-$BLOCK_DEFAULT}"; fi
is_block() { case " $block " in *" $1 "*) return 0 ;; esac; return 1; }
warn() { # $1 cổng, $2 lời — chỉ báo, không đỏ
  warned=$((warned + 1)); summary="$summary\n  ~  $1  $2 — CHỈ BÁO, không chặn"
  if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::warning title=gate-chain $1::$2 (chỉ báo, không chặn — handbook CI.md nguyên tắc 2)"; fi
}

reg="${GATE_REGISTRY:-docs/GATES.md}"
pass=0; failn=0; broken=0; skipped=0; warned=0; summary=""
echo "gate-chain: cổng chặn = [${block:-không có}] · còn lại chỉ báo"
for g in $GATES; do
  case " ${GATE_SKIP:-} " in
    *" $g "*)
      echo "== $g: BỎ QUA (GATE_SKIP)"
      if [ -f "$reg" ] && tr -d '\r' < "$reg" | grep -F "| \`$g\`" | grep -q 'N/A'; then
        skipped=$((skipped + 1)); summary="$summary\n  -  $g  bỏ qua (N/A trong sổ)"
      elif is_block "$g"; then
        echo "  x $g là cổng CHẶN, nằm trong GATE_SKIP mà sổ $reg không có dòng \`$g\` ghi N/A + lý do"
        failn=$((failn + 1)); summary="$summary\n  x  $g  bỏ qua cổng chặn KHÔNG khai N/A"
      else
        warn "$g" "bỏ qua mà sổ $reg không khai N/A"
      fi
      continue ;;
  esac
  if [ ! -f "$HERE/check-$g.sh" ]; then
    echo "GATE $g: BROKEN - không thấy $HERE/check-$g.sh"
    if is_block "$g"; then broken=$((broken + 1)); summary="$summary\n  !! $g  BROKEN"; else warn "$g" "BROKEN (không thấy script)"; fi
    continue
  fi
  echo "== $g"
  bash "$HERE/check-$g.sh" "$@"; rc=$?
  case $rc in
    0) pass=$((pass + 1)); summary="$summary\n  v  $g" ;;
    1) if is_block "$g"; then failn=$((failn + 1)); summary="$summary\n  x  $g  VI PHẠM"; else warn "$g" "vi phạm"; fi ;;
    *) if is_block "$g"; then broken=$((broken + 1)); summary="$summary\n  !! $g  BROKEN (mã $rc)"; else warn "$g" "BROKEN (mã $rc)"; fi ;;
  esac
done
printf '\ngate-chain:%b\n' "$summary"
echo "gate-chain: $pass đạt · $failn vi phạm chặn · $broken BROKEN chặn · $warned chỉ báo · $skipped bỏ qua có khai"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  { echo "### gate-chain"; echo; echo "Cổng chặn: \`${block:-không có}\` · còn lại chỉ báo (handbook \`standards/CI.md\` nguyên tắc 2)"; echo; echo '```'; printf '%b\n' "$summary"; echo '```'; } >> "$GITHUB_STEP_SUMMARY"
fi
[ "$broken" -gt 0 ] && exit 2
[ "$failn" -gt 0 ] && exit 1
exit 0
