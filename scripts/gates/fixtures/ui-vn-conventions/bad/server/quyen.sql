CREATE FUNCTION cap_quyen(p_code text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'mã quyền % chỉ cấp bằng lệnh vận hành có nhật ký (cap-quyen-van-hanh)', p_code;
  RAISE EXCEPTION 'cần quyền platform.tenant.manage ở tổ chức vận hành';
END $$;
