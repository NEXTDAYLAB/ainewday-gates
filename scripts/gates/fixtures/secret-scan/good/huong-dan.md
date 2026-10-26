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
