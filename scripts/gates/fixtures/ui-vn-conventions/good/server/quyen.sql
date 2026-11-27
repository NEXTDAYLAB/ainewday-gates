-- Chú thích được nhắc mã: knowledge.hr_unlock, cap_quyen() — chú thích không hiện cho người dùng.
CREATE FUNCTION cap_quyen(p_code text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  RAISE NOTICE 'cap_quyen: % (ghi nhật ký được nhắc mã)', p_code;
  RAISE EXCEPTION 'Quyền này chỉ quản trị nền tảng cấp được. Liên hệ NextDayLab nếu cần.' USING HINT = 'knowledge.hr_unlock';
  RAISE EXCEPTION 'Tên miền chưa đúng dạng (vd congty.vn).';
END $$;
