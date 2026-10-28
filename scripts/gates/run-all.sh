#!/usr/bin/env bash
# Runner của chuỗi gate-chain — chạy MỌI cổng dùng chung trên repo hiện tại (thư mục làm việc = gốc repo gọi).
# Workflow .github/workflows/gate-chain.yml gọi ĐÚNG tệp này; trên máy: bash <handbook>/scripts/gates/run-all.sh
#
# DANH SÁCH DƯỚI ĐÂY LÀ NƠI DUY NHẤT CỔNG DÙNG CHUNG ĐƯỢC CHẠY (cổng gate-is-invoked đối chiếu từng dòng).
# Thêm cổng = thêm script check-<tên>.sh + ca kiểm âm fixtures/<tên>/{bad,good} + một dòng ở đây.
#
# Biến:  GATE_SKIP="tên1 tên2"   cổng không áp cho repo — mỗi tên PHẢI có dòng trong sổ cổng ghi N/A + lý do,
#                                 nếu không thì tính là vi phạm (bỏ qua phải thành văn — GATES template luật 4).
#        GATE_DIR, GATE_REGISTRY, GATE_PITFALLS, GATE_BASE_REF, GATE_RUNNERS — xem lib/gate.sh và từng cổng.
# Mã thoát: 0 đạt · 1 có vi phạm · 2 có cổng BROKEN (ưu tiên 2).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
GATES="
gate-three-states
gate-has-negative-case
gate-is-invoked
gate-not-removed
gate-registry-in-sync
gate-not-overdue
doc-ids-unique
pitfall-has-gate
tech-stack-approved
scripts-lf-executable
secret-scan
ui-vn-conventions
"
GATE_CHAIN_GATES="$(printf '%s' "$GATES" | tr '\n' ' ')"
export GATE_CHAIN_GATES

reg="${GATE_REGISTRY:-docs/GATES.md}"
pass=0; failn=0; broken=0; skipped=0; summary=""
for g in $GATES; do
  case " ${GATE_SKIP:-} " in
    *" $g "*)
      echo "== $g: BỎ QUA (GATE_SKIP)"
      if [ -f "$reg" ] && tr -d '\r' < "$reg" | grep -F "| \`$g\`" | grep -q 'N/A'; then
        skipped=$((skipped + 1)); summary="$summary\n  -  $g  bỏ qua (N/A trong sổ)"
      else
        echo "  x $g nằm trong GATE_SKIP mà sổ $reg không có dòng \`$g\` ghi N/A + lý do"
        failn=$((failn + 1)); summary="$summary\n  x  $g  bỏ qua KHÔNG khai N/A"
      fi
      continue ;;
  esac
  [ -f "$HERE/check-$g.sh" ] || { echo "GATE $g: BROKEN - không thấy $HERE/check-$g.sh"; broken=$((broken + 1)); summary="$summary\n  !! $g  BROKEN"; continue; }
  echo "== $g"
  bash "$HERE/check-$g.sh" "$@"; rc=$?
  case $rc in
    0) pass=$((pass + 1)); summary="$summary\n  v  $g" ;;
    1) failn=$((failn + 1)); summary="$summary\n  x  $g  VI PHẠM" ;;
    *) broken=$((broken + 1)); summary="$summary\n  !! $g  BROKEN (mã $rc)" ;;
  esac
done
printf '\ngate-chain:%b\n' "$summary"
echo "gate-chain: $pass đạt · $failn vi phạm · $broken BROKEN · $skipped bỏ qua có khai"
[ "$broken" -gt 0 ] && exit 2
[ "$failn" -gt 0 ] && exit 1
exit 0
