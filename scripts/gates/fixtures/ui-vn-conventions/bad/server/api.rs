fn kiem(x: u8) -> Result<(), String> {
    if x == 0 { return Err("tenant chưa nạp vai chuẩn (kernel.seed_auth_catalog)".into()); }
    Err(format!("thiếu app_user_id cho người dùng"))
}
