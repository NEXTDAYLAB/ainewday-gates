// Ca ĐỎ: đủ 4 luật đọc được từ mã nguồn (giống những gì PO gặp khi UAT EH 27/10/2026).
export function ParameterScreen({ p, err }: { p: { key: string; id: string; max: number }; err: { code: string } }) {
  return (
    <form>
      <label>Hạn mặc định</label>
      <input type="number" value={p.max} />
      <input inputMode="decimal" />
      <p>{p.key}</p>
      <span>Đối tượng: {p.id}</span>
      <td>COUNT_DEFAULT_DEADLINE_DAYS</td>
      <small>Cho phép đến {Number.MAX_SAFE_INTEGER} đ</small>
      <small>Tối đa 9.007.199.254.740.991 đ</small>
      <input type="date" />
      <span>{new Date().toLocaleDateString()}</span>
      <span>{new Date().toLocaleString("en-US")}</span>
      <span>{format(d, "MM/dd/yyyy")}</span>
      <p className="error">{err.code}</p>
      <input value="1" /> {/* ui-vn-ok: */}
    </form>
  );
}
