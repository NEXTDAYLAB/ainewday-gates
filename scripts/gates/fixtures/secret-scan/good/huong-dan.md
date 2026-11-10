# Hướng dẫn (ca xanh — văn xuôi kỹ thuật dễ bắt nhầm, đo từ báo nhầm thật trên handbook 26/10/2026)

Mật khẩu: argon2id, tham số theo SECURITY §1.
Mật khẩu cơ sở dữ liệu nằm trong biến `DATABASE_URL`, giá trị ở kho bí mật.
matkhau: <thay-bang-gia-tri-that>
Khoá: lấy từ kho bí mật, không ghi ở đây.
pass: true
Cổng bypass được nếu ghi `allow-hardcode: lý do`.
password: ${{ secrets.DB_PASSWORD }}
Giữ đúng **khoá cũ** khi sửa: `m01-ho-so-khach-hang`.

| `no-pii-in-logs` | Log không ghi token | khoá ở HL; còn lại chưa | HL `check-khong-log-bi-mat.sh` |
| L9 | án lệ | khoá ở một dự án nội bộ | một dự án nội bộ `check-pitfall-has-gate.sh` |
Đối chiếu khoá SSH với sổ khoá; lệch ⇒ P1. Chủ: devops-team

## Bắt nhầm đã xác minh ở EHB-SM + EH-AMS (06–10/11/2026) — phải XANH
| Đăng nhập chỉ mật khẩu | `AuthMethod.PASSWORD` · `Role.fieldLogin` · tham số `FIELD_SESSION_IDLE_TIMEOUT_MINUTES` |
| Mật khẩu tạm | `User.mustChangePassword` + `tempPasswordExpiresAt` | Máy chủ sinh, hiện một lần |
| Danh mục | Vai nào chỉ mật khẩu | Cờ `Role.fieldLogin` (superadmin) |
CHT + QLV chỉ mật khẩu (cờ `Role.fieldLogin` + công tắc `FIELD_TWO_FACTOR`), phiên điện thoại dài `FIELD_SESSION_*`.
Superadmin tạo U → nhận `temporaryPassword` t; `DISPLAY_NAME=`"EH Thử" → mật khẩu mới m
L đã khoá (biết mật khẩu); tên `khong.co.ai` mật khẩu bất kỳ
7b. **Mã xác thực bắt buộc ở đường mật khẩu:** realm dùng luồng `eh-browser` (`browserFlow`)
Bỏ phụ thuộc hộp thư đổi mật khẩu**. `hoadon@` đổi người giữ
Sổ tay: tạo vai NOLOGIN, lấy mật khẩu từ `staging.env`.
Tệp khoá tài khoản dịch vụ: **Bitwarden**
Khoá = `app_user.status = locked` + tắt người ở Keycloak
