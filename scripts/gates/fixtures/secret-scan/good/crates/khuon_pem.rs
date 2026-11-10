// Bắt nhầm đã xác minh (EHB-SM gmail_service_account.rs, PR #103): khuôn PEM, thân khoá sinh lúc chạy — phải XANH
fn pem(lines: Vec<&str>) -> String {
    format!(
        "-----BEGIN PRIVATE KEY-----\n{}\n-----END PRIVATE KEY-----\n",
        lines.join("\n")
    )
}

#[test]
fn khuon_dung_dau_cuoi() {
    let p = pem(vec!["AAAA"]);
    assert!(p.ends_with("-----END PRIVATE KEY-----\n"));
}
