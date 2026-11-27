# ui-vn-conventions · luật 2 (phía máy chủ) — câu người dùng đọc (chuỗi có chữ ngoài ASCII, tức tiếng Việt) mà lẫn MÃ NỘI BỘ.
# anh Châu quyết 27/11/2026 (chat): "thông báo lỗi của phần mềm phải rõ nghĩa cho người dùng" — luật 2 đã có, đây là răng cho phía máy chủ.
# Chạy với LC_ALL=C: byte ngoài ASCII (\200-\377) = chữ Việt ⇒ chuỗi người dùng đọc. Chuỗi toàn ASCII là mã / khoá, không xét.
# In: tệp<TAB>dòng<TAB>mã bắt được<TAB>chuỗi (cắt 120). Một dòng báo tối đa một lần.
function trim(s) { sub(/^[ \t]+/, "", s); return s }
function la_ten_mien(t,  p) { p = t; sub(/^.*[.]/, "", p); return p ~ /^(vn|com|org|net|io|gov|edu|xlsx|xls|csv|pdf|json|xml|zip|png|jpg|jpeg|docx|txt|html)$/ }
function ma_noi_bo(s,  t) {
  # a.b hoặc a.b.c (mã quyền, bảng, hàm có lược đồ) — trừ tên miền / đuôi tệp / viết tắt "vd." "tp."
  if (match(s, /(^|[^A-Za-z0-9_.\/@:-])[a-z][a-z0-9_]*([.][a-z][a-z0-9_]*)+([^A-Za-z0-9_.]|[.][^a-z]|[.]$|$)/)) {
    t = substr(s, RSTART, RLENGTH); gsub(/^[^a-z]+/, "", t); gsub(/[^a-z0-9_]+$/, "", t)
    if (!la_ten_mien(t) && t !~ /^(v|tr|vd|tp|q|p|tt|nd|qd|so)[.]/) return t
  }
  # ten_ham(
  if (match(s, /(^|[^A-Za-z0-9_])[a-z_][a-z0-9_]{2,}[(]/)) { t = substr(s, RSTART, RLENGTH); gsub(/^[^a-z_]+/, "", t); return t ")" }
  # ten_bien (có gạch dưới)
  if (match(s, /(^|[^A-Za-z0-9_\/.-])[a-z][a-z0-9]*_[a-z0-9_]*[a-z0-9]([^A-Za-z0-9_.\/-]|$)/)) {
    t = substr(s, RSTART, RLENGTH); gsub(/^[^a-z]+/, "", t); gsub(/[^a-z0-9_]+$/, "", t); return t
  }
  # (ten-lenh)
  if (match(s, /[(][a-z0-9]+(-[a-z0-9]+)+[)]/)) return substr(s, RSTART, RLENGTH)
  return ""
}
{
  line = $0; sub(/\r$/, "", line); l = trim(line)
  if (l ~ /^(\/\/|--|#|[*]|\/[*]|<!--)/) next
  if (l ~ /(tracing::|log::|(^|[^a-z_])(info|warn|error|debug|trace)!\(|console[.]|logger[.]|logging[.]|RAISE (NOTICE|LOG|DEBUG|WARNING|INFO)|eprintln!|println!|dbg!)/) next
  if (l ~ /ui-vn-ok:[ \t]*[^ \t*}>-]/) next
  if (length(line) > 400) next                       # mã đã nén (thư viện ngoài)
  if (line ~ /COMMENT ON /) next                     # chú thích cột CSDL — người dùng không đọc
  # Chỉ dòng SINH lỗi / thông báo cho người dùng (lời nhắc AI, mô tả, chú thích dữ liệu không phải câu người dùng đọc — đo 27/11: 8 kho).
  if (line !~ /(RAISE EXCEPTION|Err[(]|bail!|anyhow!|throw |Exception[(]|Error[(]|[Ee]rror[ \t]*[:=]|[Mm]essage[ \t]*[:=]|toast|[Ll]oi[A-Za-z_]*[ \t]*[(:=]|sai[(]|thong_bao|abort[(]|reject[(]|HTTPException)/) next
  rest = line
  while (match(rest, /"[^"]*"|'([^']|'')*'/)) {
    s = substr(rest, RSTART + 1, RLENGTH - 2); rest = substr(rest, RSTART + RLENGTH)
    if (s !~ /[\200-\377]/) continue
    gsub(/[$]?[{][^}]*[}]/, " ", s)                  # biến chèn {x} ${x} — máy thay giá trị trước khi hiện
    gsub(/%[A-Za-z0-9_]*/, " ", s)                    # chỗ chèn %s, %
    t = ma_noi_bo(s)
    if (t != "") { printf "%s\t%d\t%s\t%s\n", FILENAME, FNR, t, substr(s, 1, 120); break }
  }
}
