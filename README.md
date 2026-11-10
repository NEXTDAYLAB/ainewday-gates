# ainewday-gates

Chuỗi cổng CI dùng chung (`gate-chain`) của AI NewDay — kho **công khai**, chỉ chứa mã kiểm, không chứa dữ liệu hay nghiệp vụ.

Mỗi repo dự án gọi **một job**:

```yaml
jobs:
  gate-chain:
    uses: NEXTDAYLAB/ainewday-gates/.github/workflows/gate-chain.yml@main
    with:
      po-name: "<tên người duyệt tech stack>"   # tuỳ chọn
      skip: ""                                   # cổng không áp: nên có dòng N/A + lý do trong docs/GATES.md
      # block: "secret-scan"                     # mặc định — cổng làm job đỏ; cổng còn lại chỉ báo
      # strict: true                             # mọi cổng chặn (hành vi cũ) — chỉ khi có bằng chứng
```

**Chặn hay chỉ báo** *(anh Châu quyết 10/11/2026 (chat) — handbook `standards/CI.md` nguyên tắc 2–3)*: CI chỉ chặn lỗi thật.
Trong chuỗi này **chỉ `secret-scan` chặn**; 4 cổng còn lại vi phạm ⇒ cảnh báo (`::warning::` + bảng tóm tắt), job vẫn xanh.
Cổng mới thêm vào chuỗi **mặc định chỉ báo**; chỉ vào danh sách chặn (`BLOCK_DEFAULT` trong `run-all.sh`) khi đã bắt lỗi sản phẩm thật.

Chuỗi chạy **5 cổng** *(dọn luật — anh Châu quyết 03/11/2026 (chat))*:

| Cổng | Bảo đảm | Mặc định |
|---|---|:-:|
| `tech-stack-approved` | Có mã ứng dụng ⇒ `docs/decisions/ADR-000*` có dòng `Duyệt:`/`Miễn trình:` đã điền | chỉ báo |
| `scripts-lf-executable` | `.gitattributes` ép LF; script không CRLF, có bit chạy | chỉ báo |
| `ui-vn-conventions` | Giao diện theo Quy ước giao diện người dùng VN (handbook `standards/UI_VN.md`): ô số/ngày qua thành phần chung, không lộ mã máy, không giới hạn máy, không ngày kiểu Mỹ | chỉ báo |
| `mockup-logo-goc` | Khách có `docs/brand/logo/` ⇒ mockup `docs/mockup/index.html` nhúng logo gốc, không giữ ô chữ viết tắt của khung (skill mockup luật 15) | chỉ báo |
| `secret-scan` | gitleaks + luật cho cách ghi tiếng Việt (`mật khẩu:`, `pass =`, `khoá:`) | **chặn** |

**Thư viện tham khảo (không chạy trong chuỗi):** `gate-three-states` · `gate-has-negative-case` · `gate-is-invoked` · `gate-not-removed` ·
`gate-registry-in-sync` · `gate-not-overdue` · `doc-ids-unique` · `pitfall-has-gate` — 8 cổng sổ sách, gỡ khỏi chuỗi 03/11/2026 vì
đỏ 87–100% lượt mà không bắt lỗi sản phẩm nào. Script vẫn ở `scripts/gates/` (còn ca kiểm âm); repo nào thật cần thì tự gọi trong CI riêng.

Thêm một cổng vào chuỗi ⇒ bỏ một cổng (chống phình, handbook `standards/LUAT.md` mục C).

Mã thoát: 0 đạt (có thể kèm cảnh báo) · 1 cổng chặn vi phạm · 2 cổng chặn BROKEN. Tự kiểm: `bash scripts/gates/test-gates.sh` (mọi cổng đỏ trên `fixtures/<cổng>/bad`, xanh trên `good`).
Mọi giá trị "bí mật" trong `fixtures/` là chuỗi **giả**.
