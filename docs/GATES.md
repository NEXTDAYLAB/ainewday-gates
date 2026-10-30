# GATES — sổ cổng của chính `ainewday-gates`

> Kho này **dogfood**: tự chạy chuỗi `gate-chain` mà nó phát cho mọi repo (workflow `.github/workflows/gate-chain-selftest.yml`, job `dogfood`).
> Ở đây "cổng riêng" chính là bộ cổng dùng chung `scripts/gates/check-*.sh` (`GATE_DIR=scripts/gates`, runner `scripts/gates/run-all.sh`).
> **Đợt hiện tại:** `Đ0` <!-- gate-not-overdue so cột "Bật ở" với dòng này -->
> **Thứ tự đợt:** Đ0, Đ1, Đ2, Đ3

## Luật của sổ

1. Cổng mới phải có dòng ở đây TRƯỚC khi merge. Tên ở đây là định danh chính thức (`scripts/gates/check-<tên>.sh`).
2. Trạng thái: `☐` chưa dựng · `🟡` có script, chưa có ca kiểm âm · `✅` chạy trong CI, ca kiểm âm chạy mỗi PR (`test-gates.sh`).
3. Cổng không áp cho kho này: `N/A` + lý do, và tên nằm trong `GATE_SKIP` của job `dogfood` (runner đối chiếu).

## Danh sách cổng

| Cổng | Bảo đảm | Loại | Nguồn (luật/ADR/PITFALLS) | Ca kiểm âm | Bật ở | TT |
|---|---|:-:|---|---|:-:|:-:|
| `gate-three-states` | Cổng dùng thư viện `gate.sh`: thoát 0/1/2, thiếu công cụ = BROKEN; không nuốt mã thoát | lock | GATES §1 · LUAT L1 | `fixtures/gate-three-states` (không thư viện; gate_finish bị nuốt mã thoát) | Đ0 | ✅ |
| `gate-has-negative-case` | Mọi cổng có `fixtures/<tên>/` git theo dõi | lock | GATES §2 #2 · LUAT L1 | cổng không có thư mục fixture | Đ0 | ✅ |
| `gate-is-invoked` | Mọi cổng có tên trong runner; workflow không có `if: hashFiles(...)` | lock | GATES §2 #3 · LUAT L1 · án lệ nội bộ | cổng chỉ có tên trong chú thích; bước bọc `if: hashFiles` | Đ0 | ✅ |
| `gate-not-removed` | Cổng có ở nhánh gốc mà biến mất ⇒ phải có dòng ở "Cổng đã gỡ" | lock | bản mẫu nội bộ  | xoá cổng `b` không khai lý do | Đ0 | ✅ |
| `gate-registry-in-sync` | Sổ ↔ script khớp hai chiều (cả cổng của chuỗi) | lock | GATES §2 #1 | cổng thiếu dòng; dòng ✅ không script | Đ0 | ✅ |
| `gate-not-overdue` | Dòng ☐/🟡 quá "Bật ở" không gia hạn PO ⇒ đỏ; án lệ quá 7 ngày chưa đóng ⇒ đỏ | lock | GATES §2 #4 · LUAT §2.2–2.3, L9 | trễ theo đợt, theo ngày, gia hạn hết hạn; án lệ 12 và 25 ngày | Đ0 | ✅ |
| `doc-ids-unique` | Số ADR/PITFALLS không trùng, không nhảy | lock | GATES §2 #5 · LUAT L9 | ADR trùng 0001 + nhảy 0002; P-002 trùng + nhảy P-003 | Đ0 | ✅ |
| `pitfall-has-gate` | Mục án lệ nào cũng có dòng **Cổng đóng bẫy:** | camera | LUAT L9 · ENGINEERING §4 | mục thiếu dòng | Đ0 | N/A — kho công cụ không có `docs/PITFALLS.md`: án lệ ghi ở kho bài học của công ty |
| `tech-stack-approved` | Có mã ứng dụng ⇒ ADR-000 có `Duyệt:`/`Miễn trình: <người duyệt>` (+ `tech-stack.html` khi Duyệt) | lock | LUAT L8 · BH-007, BH-033 | ADR-000 tự ghi Accepted, `Duyệt: PO <ngày>` chưa điền | Đ0 | ✅ |
| `scripts-lf-executable` | `.gitattributes` ép LF; `.sh` không CR trong index, mode 100755 | lock | LUAT L10 · BH-031 | thiếu `.gitattributes`, `.sh` CRLF + 100644 | Đ0 | ✅ |
| `ui-vn-conventions` | Tệp giao diện (.tsx .jsx .vue .svelte .astro .html, ngoài test/build) theo Quy ước giao diện người dùng VN luật 1–4: không ô số/ngày gốc ngoài thành phần chung, không mã máy/`{x.key}`/`{err.code}` hiện ra, không giới hạn máy, không ngày kiểu Mỹ; ngoại lệ `ui-vn-ok: <lý do>` / `.ui-vn-ignore` phải có lý do | lock | handbook `standards/UI_VN.md` · LUAT L11 · BH-048 | `type="number"`, `inputMode="decimal"`, `{p.key}`, `Đối tượng: {p.id}`, `COUNT_DEFAULT_DEADLINE_DAYS` giữa thẻ, `MAX_SAFE_INTEGER` hiện ra, `9.007.199.254.740.991`, `type="date"`, `toLocaleDateString()`, `MM/dd/yyyy`, `ui-vn-ok:` trống, `.ui-vn-ignore` thiếu lý do | Đ0 | ✅ |
| `mockup-logo-goc` | Khách có `docs/brand/logo/` ⇒ `docs/mockup/index.html` nhúng logo gốc (`data:image/` cạnh chữ `logo`), không giữ ô chữ viết tắt của khung | lock | skill `ainewday-mockup-standard` luật 15 · EHB-SM 30/10/2026 | `BRAND.logo:''` + ô chữ `KH` khi đã có `docs/brand/logo/` | Đ0 | ✅ |
| `secret-scan` | Không bí mật trong lịch sử + cây làm việc; bắt cách ghi tiếng Việt | camera | LUAT L2 · BH-011, BH-037 · án lệ nội bộ | `matkhau:` trần, `Mật khẩu sudo` trong bảng, `Khoá API` nháy ngược, `pass =` — giá trị GIẢ | Đ0 | ✅ |

Giới hạn đã biết (camera): `secret-scan` — bí mật viết khác mẫu (không nhãn, nhãn lạ, entropy thấp) lọt; `pitfall-has-gate` — chỉ kiểm có dòng,
không kiểm cổng ghi trong dòng có thật; `tech-stack-approved` — đọc chữ, không biết ai gõ dòng "Duyệt" (lớp chặn là review PR có ADR-000);
`gate-three-states` — kiểm script có dùng thư viện, không chạy thử từng script; `mockup-logo-goc` — không so ảnh nhúng có đúng tệp trong `docs/brand/logo/`.

## Gia hạn (PO duyệt)

| Cổng | Hạn cũ | Hạn mới | Lý do | PR duyệt |
|---|---|---|---|---|

## Z. Cổng đã gỡ

Gỡ một cổng không bị cấm — gỡ trong im lặng mới bị cấm (`gate-not-removed`). Mỗi dòng: tên cổng trong dấu `, ngày, lý do, ai quyết.
