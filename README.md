# ainewday-gates

Chuỗi cổng CI dùng chung (`gate-chain`) của AI NewDay — kho **công khai**, chỉ chứa mã kiểm, không chứa dữ liệu hay nghiệp vụ.

Mỗi repo dự án gọi **một job**:

```yaml
jobs:
  gate-chain:
    uses: NEXTDAYLAB/ainewday-gates/.github/workflows/gate-chain.yml@main
    with:
      po-name: "<tên người duyệt tech stack>"   # tuỳ chọn
      skip: ""                                   # cổng không áp: phải có dòng N/A + lý do trong docs/GATES.md
```

Chuỗi chỉ chạy **cổng thật** — cổng chặn lỗi sản phẩm/bảo mật *(anh Châu quyết 03/11/2026 (chat) — dọn luật)*:

| Cổng | Bảo đảm |
|---|---|
| `tech-stack-approved` | Có mã ứng dụng ⇒ `docs/decisions/ADR-000*` có dòng `Duyệt:`/`Miễn trình:` đã điền |
| `scripts-lf-executable` | `.gitattributes` ép LF; script không CRLF, có bit chạy |
| `ui-vn-conventions` | Giao diện theo Quy ước giao diện người dùng VN (handbook `standards/UI_VN.md`): ô số/ngày qua thành phần chung, không lộ mã máy, không giới hạn máy, không ngày kiểu Mỹ |
| `mockup-logo-goc` | Khách có `docs/brand/logo/` ⇒ mockup `docs/mockup/index.html` nhúng logo gốc, không giữ ô chữ viết tắt của khung (skill mockup luật 15) |
| `secret-scan` | gitleaks + luật cho cách ghi tiếng Việt (`mật khẩu:`, `pass =`, `khoá:`) |

**Thư viện tham khảo (không chạy trong chuỗi):** `gate-three-states` · `gate-has-negative-case` · `gate-is-invoked` · `gate-not-removed` ·
`gate-registry-in-sync` · `gate-not-overdue` · `doc-ids-unique` · `pitfall-has-gate` — 8 cổng sổ sách, gỡ khỏi chuỗi 03/11/2026 vì
đỏ 87–100% lượt mà không bắt lỗi sản phẩm nào. Script vẫn ở `scripts/gates/` (còn ca kiểm âm); repo nào thật cần thì tự gọi trong CI riêng.

Thêm một cổng vào chuỗi ⇒ bỏ một cổng (chống phình, handbook `standards/LUAT.md` mục C).

Mã thoát: 0 đạt · 1 vi phạm · 2 BROKEN. Tự kiểm: `bash scripts/gates/test-gates.sh` (mọi cổng đỏ trên `fixtures/<cổng>/bad`, xanh trên `good`).
Mọi giá trị "bí mật" trong `fixtures/` là chuỗi **giả**.
