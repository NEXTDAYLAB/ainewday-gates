fn kiem(x: u8) -> Result<(), String> {
    tracing::warn!("thiếu app_user_id"); // nhật ký được nhắc mã
    if x == 0 { return Err("Tổ chức chưa sẵn sàng, thử lại sau ít phút.".into()); }
    let _ma = "platform.tenant.manage"; // chuỗi không có tiếng Việt = mã, không phải câu người dùng
    Err("Bạn chưa có quyền xem màn này. Xem tệp bao-cao.xlsx hoặc https://mini.nextdaylab.org.".into())
}
