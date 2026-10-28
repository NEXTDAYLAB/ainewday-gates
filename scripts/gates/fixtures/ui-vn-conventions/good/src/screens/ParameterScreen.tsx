// Ca XANH: dùng thành phần chung, hiện tên tiếng Việt, mã nghiệp vụ (mã tài sản) được phép.
import { NumberInput } from "../components/inputs/NumberInput";
export function ParameterScreen({ p, asset }: { p: { displayName: string; id: string }; asset: { code: string } }) {
  return (
    <ul>
      <li key={p.id}>{p.displayName}</li>
      <li>Mã tài sản: {asset.code}</li>
      <li>Ngày: {formatVnDate(p.id)}</li>
      <li>FAST · QR · CSV</li>
      <NumberInput value="5000000" onValueChange={() => {}} />
      <a href={`/tham-so/${p.id}`}>Mở</a>
      <input type="time" /> {/* ui-vn-ok: ô giờ ca trực dùng bàn phím số trên máy quét cầm tay — PO duyệt 28/10 */}
    </ul>
  );
}
// Dùng MAX_SAFE_INTEGER trong logic (không hiện ra) và mã lỗi làm key React — không phải vi phạm.
export const rank = (i: number) => (i < 0 ? Number.MAX_SAFE_INTEGER : i);
export const Errors = ({ errs }: { errs: { code: string; message: string }[] }) => (
  <ul>{errs.map((e) => <li key={`${e.code}-${e.message}`}>{e.message}</li>)}</ul>
);
