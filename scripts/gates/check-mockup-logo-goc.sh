#!/usr/bin/env bash
# mockup-logo-goc (lock) — khách đã có bộ nhận diện (docs/brand/logo/) ⇒ mockup phải NHÚNG tệp logo gốc,
# không giữ ô chữ viết tắt của khung / vẽ lại logo bằng chữ.
# skill ainewday-mockup-standard luật 15 · căn cứ EHB-SM 30/10/2026 (mockup S0 vẽ ô tím + chữ "EH", trái Brand Guidelines §1).
#
#  Không có docs/mockup/index.html                 ⇒ không áp (ghi chú).
#  Không có ảnh trong docs/brand/logo/            ⇒ khách chưa có bộ nhận diện, logo TẠM được phép (ghi chú).
#  Có cả hai ⇒ mockup phải có chữ "logo" và một ảnh nhúng `data:image/` cách nhau ≤ 300 ký tự
#  (khung chuẩn: `BRAND = { logo:'data:image/…' }`; mockup tự dựng: `<img class="…logo…" src="data:image/…">`).
# Giới hạn (ghi trong sổ): cổng không so ảnh nhúng có ĐÚNG là tệp trong docs/brand/logo/ — chỉ chặn ca "không nhúng logo nào".
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
gate_init "mockup-logo-goc" "$@"

m="docs/mockup/index.html"
if [ ! -f "$m" ]; then gate_note "không có $m"; gate_finish; fi
logos="$(ls docs/brand/logo 2>/dev/null | grep -iE '\.(png|svg|jpe?g|webp)$' | head -3 | tr '\n' ' ')"
if [ -z "$logos" ]; then
  gate_note "chưa có ảnh trong docs/brand/logo/ — khách chưa có bộ nhận diện, logo TẠM được phép"
  gate_finish
fi
if gate_cat "$m" | grep -qiE 'logo.{0,300}data:image/'; then
  gate_note "$m nhúng logo (docs/brand/logo/: $logos)"
else
  gate_violation "$m — khách có logo gốc (docs/brand/logo/: $logos) nhưng mockup không nhúng logo: đặt BRAND.logo = data:image/… của tệp gốc (skill ainewday-mockup-standard luật 15), không giữ ô chữ viết tắt"
fi
gate_finish
