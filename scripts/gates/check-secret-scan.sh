#!/usr/bin/env bash
# secret-scan (camera) — không bí mật trong lịch sử git và cây làm việc (LUAT §5 L2 · BH-011, BH-037).
# Cấu hình công ty: scripts/gates/gitleaks.toml (luật mặc định + cách ghi tiếng Việt "mật khẩu:", "pass:", "khoá:").
# Repo có .gitleaks.toml riêng ⇒ chạy thêm một lượt với cấu hình đó.
# Chế độ repo: quét lịch sử git + cây làm việc. Chế độ fixture (--root): quét thư mục.
# Phạm vi lịch sử (06/11/2026 — EHB-SM: bắt nhầm ở một nhánh làm đỏ MỌI PR đang mở vì gitleaks mặc định quét `--all`):
#   có ref gốc (--base / $GATE_BASE_REF, gate-chain truyền: PR ⇒ nhánh đích, push ⇒ commit trước lượt đẩy)
#     ⇒ chỉ commit của lượt này: <gốc>..HEAD (commit bí mật rồi xoá trong cùng PR vẫn bị bắt);
#   không có gốc / gốc = HEAD ⇒ toàn lịch sử nhánh hiện tại (HEAD);
#   GATE_SECRET_FULL=1 ⇒ mọi nhánh đã fetch (`--all`, như cũ) — dùng cho lượt quét định kỳ.
# Thiếu gitleaks ⇒ BROKEN (2), không bao giờ "0 phát hiện".
# Khái quát từ một dự án nội bộ check-gitleaks.sh. Camera: chuỗi bí mật viết khác mẫu sẽ lọt (giới hạn ghi trong sổ).
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
company_cfg="$(cd "$(dirname "$0")" && pwd)/gitleaks.toml"  # tính TRƯỚC gate_init (gate_init đổi thư mục)
gate_init "secret-scan" "$@"
gate_require_tool gitleaks
[ -f "$company_cfg" ] || gate_broken "không thấy cấu hình công ty $company_cfg"

run() { # $1 = mô tả, $2 = cấu hình, còn lại = lệnh con + tham số gitleaks
  local what="$1" cfg="$2" out rc n i; shift 2
  out="$(gitleaks "$@" --config "$cfg" --no-banner --no-color --redact --exit-code 1 -v 2>&1)"; rc=$?
  case $rc in
    0) ;;
    1) printf '%s\n' "$out" | grep -E '^(Finding|File|Line|RuleID|Commit):' | sed 's/^/    /'
       n=$(printf '%s\n' "$out" | grep -c '^Finding:'); [ "$n" -gt 0 ] || n=1
       i=0; while [ $i -lt "$n" ]; do gate_violation "$what — bí mật phát hiện (chi tiết ở trên, giá trị đã che)"; i=$((i + 1)); done ;;
    *) gate_broken "gitleaks thoát mã $rc ($what): $(printf '%s' "$out" | tail -3)" ;;
  esac
}

# Dải commit quét lịch sử (xem đầu tệp)
log_opts="--all"; scope="mọi nhánh"
if gate_repo_mode && [ "${GATE_SECRET_FULL:-0}" != 1 ]; then
  head="$(git rev-parse -q --verify HEAD^{commit} 2>/dev/null)" || gate_broken "repo chưa có commit nào"
  base="$(git rev-parse -q --verify "${GATE_BASE_REF:-}^{commit}" 2>/dev/null || true)"
  if [ -n "$base" ] && [ "$base" != "$head" ]; then log_opts="$base..HEAD"; scope="commit của lượt này ($GATE_BASE_REF..HEAD)"
  else log_opts="HEAD"; scope="toàn lịch sử nhánh hiện tại"; fi
fi
gate_repo_mode && gate_note "phạm vi lịch sử: $scope"

cfgs="$company_cfg"
[ -f .gitleaks.toml ] && cfgs="$cfgs $(pwd)/.gitleaks.toml"
for cfg in $cfgs; do
  tag="$( [ "$cfg" = "$company_cfg" ] && echo 'cấu hình công ty' || echo '.gitleaks.toml của repo')"
  if gate_repo_mode; then
    run "lịch sử git, $tag" "$cfg" git --log-opts="$log_opts" .
    run "cây làm việc, $tag" "$cfg" dir .
  else
    run "cây thư mục, $tag" "$cfg" dir .
  fi
done

# .env được allowlist (nằm ngoài git theo thiết kế) — khẳng định giả định đó, nếu không allowlist là điểm mù.
if gate_repo_mode; then
  git ls-files | grep -E '(^|/)\.env(\.[A-Za-z0-9_-]+)?$' | grep -vE '\.(example|sample|template)$' | while IFS= read -r f; do
    gate_violation "$f bị git theo dõi trong khi gitleaks bỏ qua .env — gỡ ngay (git rm --cached \"$f\") và XOAY mọi bí mật trong đó"
  done
fi
gate_finish
