#!/usr/bin/env bash
# gate-not-removed (lock) — số cổng KHÔNG được giảm trong im lặng.
#
# Các cổng canh hệ cổng khác chỉ kiểm tính nhất quán giữa những thứ CÒN LẠI: xoá check-xyz.sh cùng dòng
# của nó trong sổ thì mọi cổng khác vẫn xanh. Cổng này so với ref gốc (--base / $GATE_BASE_REF):
# cổng riêng nào có ở gốc mà nay không còn ⇒ phải có dòng lý do ở mục "Cổng đã gỡ" của sổ
# (`## … Cổng đã gỡ`, dòng chứa `<tên>` trong dấu `).
# Không cấm gỡ — cấm gỡ trong im lặng ("hạ chuẩn phải có lý do thành văn").
#
# Tuỳ chọn: tệp khoá $GATE_DIR/gates.lock (một tên một dòng) — nếu có thì đối chiếu hai chiều với đĩa.
# Khái quát từ một dự án nội bộ check-cong-khong-bien-mat.sh ; thêm so với ref gốc vì
# bản một dự án nội bộ không bắt được ca xoá luôn cả dòng trong tệp khoá.
# Chế độ --root (không git): chỉ kiểm tệp khoá; phần so ref gốc cần git.
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
gate_init "gate-not-removed" "$@"

reg="$GATE_REGISTRY"
lock="$GATE_DIR/gates.lock"
removed_section=""
[ -f "$reg" ] && removed_section="$(gate_cat "$reg" | awk '/^## .*Cổng đã gỡ/{t=1; next} /^## /{t=0} t')"
current="$(gate_local_gates)"

check_removed() { # $1 = tên cổng không còn trên đĩa, $2 = nơi biết nó từng có
  if printf '%s' "$removed_section" | grep -qF "\`$1\`"; then
    gate_note "cổng \`$1\` đã gỡ có khai lý do — hợp lệ"
  else
    gate_violation "cổng \`$1\` có ở $2 nhưng KHÔNG còn $GATE_DIR/check-$1.sh, và không có dòng lý do ở mục \"Cổng đã gỡ\" của $reg"
  fi
}

# 1. So với ref gốc
if gate_repo_mode; then
  git rev-parse --verify --quiet "$GATE_BASE_REF^{commit}" >/dev/null \
    || gate_broken "không thấy ref gốc '$GATE_BASE_REF' (checkout thiếu lịch sử? dùng fetch-depth: 0 hoặc --base <ref>)"
  base_gates="$( { git ls-tree --name-only "$GATE_BASE_REF" -- "$GATE_DIR/" 2>/dev/null \
                   | sed -n "s|^$GATE_DIR/check-\(.*\)\.sh$|\1|p"
                 git show "$GATE_BASE_REF:$lock" 2>/dev/null | tr -d '\r' | grep -vE '^[[:space:]]*(#|$)'
               } | LC_ALL=C sort -u)"
  for name in $base_gates; do
    printf '%s\n' "$current" | grep -qxF "$name" || check_removed "$name" "$GATE_BASE_REF"
  done
  gate_note "so với $GATE_BASE_REF: $(printf '%s\n' "$base_gates" | grep -c .) cổng ở gốc, $(printf '%s\n' "$current" | grep -c .) cổng hiện tại"
fi

# 2. Tệp khoá (tuỳ chọn)
if [ -f "$lock" ]; then
  locked="$(gate_cat "$lock" | grep -vE '^[[:space:]]*(#|$)' | sed 's/[[:space:]]*$//')"
  for name in $locked; do
    printf '%s\n' "$current" | grep -qxF "$name" || check_removed "$name" "$lock"
  done
  for name in $current; do
    printf '%s\n' "$locked" | grep -qxF "$name" || gate_violation "cổng \`$name\` có trên đĩa nhưng chưa khai trong $lock — thêm một dòng"
  done
fi
gate_finish
