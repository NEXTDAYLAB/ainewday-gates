#!/usr/bin/env bash
# scripts-lf-executable (lock) — script dùng LF và có bit thực thi; repo ép LF bằng .gitattributes.
# LUAT §5 L10 · căn cứ BH-031 (Windows hay làm mất cả hai: CRLF hỏng trên runner Linux, mode 100644 ⇒ "Permission denied").
#  1. .gitattributes có dòng `* text=auto eol=lf`.
#  2. Mọi *.sh không mang CR — chế độ repo đo NỘI DUNG TRONG INDEX (`git ls-files --eol`), vì máy Windows
#     autocrlf=true cho cây làm việc CRLF dù index LF; tệp .sh chưa vào index thì đo trên đĩa.
#  3. Chế độ repo: *.sh trong index có mode 100755 (trừ $GATE_DIR/fixtures/ — dữ liệu, chạy bằng `bash <tệp>`).
#     Tệp .sh mới chưa vào index trên máy core.filemode=false ⇒ đỏ: máy đó không ghi được bit thực thi.
# Khái quát từ một dự án nội bộ check-scripts-executable.sh (thêm điều 1 và đo CR trong index).
source "$(dirname "$0")/lib/gate.sh" || exit 2  # thư viện vắng mặt ⇒ BROKEN, không chạy tiếp
gate_init "scripts-lf-executable" "$@"
TAB="$(printf '\t')"

if [ ! -f .gitattributes ] || ! gate_cat .gitattributes | grep -Eq '^\*[[:space:]]+text=auto[[:space:]]+eol=lf[[:space:]]*$'; then
  gate_violation ".gitattributes thiếu dòng '* text=auto eol=lf' — script CRLF sẽ hỏng trên runner Linux"
fi

if gate_repo_mode; then
  git ls-files --eol -- '*.sh' | grep -v "$TAB$GATE_DIR/fixtures/" | while IFS= read -r row; do
    case "$row" in i/crlf*|i/mixed*) printf '%s\n' "${row##*$TAB}" ;; esac
  done | while IFS= read -r f; do gate_violation "$f — có CR trong index (CRLF); thêm .gitattributes rồi 'git add --renormalize .'"; done

  git ls-files -s -- '*.sh' | grep -v "$TAB$GATE_DIR/fixtures/" | grep -v '^100755' | while read -r mode _ _ f; do
    printf '%s %s\n' "$mode" "$f"
  done | while read -r mode f; do gate_violation "$f — mode $mode, cần 100755 (git update-index --chmod=+x \"$f\")"; done

  git ls-files --others --exclude-standard -- '*.sh' | grep -v "^$GATE_DIR/fixtures/" | while IFS= read -r f; do
    grep -q "$(printf '\r')" "$f" && gate_violation "$f — có ký tự CR (CRLF)"
    if [ "$(git config core.filemode)" = "false" ]; then
      gate_violation "$f — tệp .sh mới chưa vào index, mà máy này không ghi được bit thực thi (core.filemode=false); chạy: git add \"$f\" && git update-index --chmod=+x \"$f\""
    fi
  done
else
  gate_files | grep -E '\.sh$' | while IFS= read -r f; do
    grep -q "$(printf '\r')" "$f" && gate_violation "$f — có ký tự CR (CRLF)"
  done
fi
gate_finish
