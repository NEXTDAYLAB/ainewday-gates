// ui-vn: thanh-phan-chung — ô số chung: ô chữ có inputMode số, hiện dấu chấm hàng nghìn khi gõ.
export function NumberInput(props: { value: string; onValueChange: (v: string) => void }) {
  return <input type="text" inputMode="numeric" value={props.value} onChange={(e) => props.onValueChange(e.target.value)} />;
}
