# GATES — sổ cổng (ca kiểm âm, hôm nay giả định 26/10/2026)

> **Đợt hiện tại:** `S0-D2`
> **Thứ tự đợt:** S0-D1, S0-D2, M1

| Cổng | Bảo đảm | Loại | Nguồn | Ca kiểm âm | Bật ở | TT |
|---|---|:-:|---|---|:-:|:-:|
| `tre-theo-dot` | ☐ mà Bật ở S0-D1 < đợt hiện tại ⇒ quá hạn | lock | — | — | S0-D1 | ☐ |
| `tre-theo-ngay` | 🟡 mà Bật ở là ngày đã qua ⇒ quá hạn | lock | — | — | 01/10/2026 | 🟡 |
| `gia-han-het` | gia hạn PO-approved nhưng hạn mới cũng đã qua | lock | — | — | S0-D1 | ☐ |
| `chua-toi-han` | ☐, Bật ở M1 > đợt hiện tại ⇒ chưa trễ | lock | — | — | M1 | ☐ |
| `da-chay` | ✅ | lock | — | — | S0-D1 | ✅ |

## Gia hạn (PO duyệt)

| Cổng | Hạn cũ | Hạn mới | Lý do | PR duyệt |
|---|---|---|---|---|
| `gia-han-het` | S0-D1 | 20/10/2026 | chờ công cụ | PO-approved #1 |
