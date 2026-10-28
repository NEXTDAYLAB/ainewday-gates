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

| Cổng | Bảo đảm |
|---|---|
| `gate-three-states` · `gate-has-negative-case` · `gate-is-invoked` · `gate-not-removed` · `gate-registry-in-sync` | Kiểm chính các cổng: thiếu công cụ = đỏ, mỗi cổng có ca kiểm âm, có nơi gọi, không lặng lẽ biến mất, sổ ↔ script khớp |
| `gate-not-overdue` · `pitfall-has-gate` · `doc-ids-unique` | Án lệ quá hạn chưa có cổng; số hiệu ADR/PITFALLS không trùng, không nhảy |
| `tech-stack-approved` | Có mã ứng dụng ⇒ `docs/decisions/ADR-000*` có dòng `Duyệt:`/`Miễn trình:` đã điền |
| `scripts-lf-executable` | `.gitattributes` ép LF; script không CRLF, có bit chạy |
| `ui-vn-conventions` | Giao diện theo Quy ước giao diện người dùng VN (handbook `standards/UI_VN.md`): ô số/ngày qua thành phần chung, không lộ mã máy, không giới hạn máy, không ngày kiểu Mỹ |
| `secret-scan` | gitleaks + luật cho cách ghi tiếng Việt (`mật khẩu:`, `pass =`, `khoá:`) |

Mã thoát: 0 đạt · 1 vi phạm · 2 BROKEN. Tự kiểm: `bash scripts/gates/test-gates.sh` (mọi cổng đỏ trên `fixtures/<cổng>/bad`, xanh trên `good`).
Mọi giá trị "bí mật" trong `fixtures/` là chuỗi **giả**.
