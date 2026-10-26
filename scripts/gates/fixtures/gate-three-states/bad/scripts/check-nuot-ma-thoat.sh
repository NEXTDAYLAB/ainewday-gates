#!/usr/bin/env bash
# Ca kiểm âm: dùng thư viện nhưng nuốt mã thoát của gate_finish.
source "$(dirname "$0")/lib/gate.sh"
gate_init "nuot-ma-thoat" "$@"
gate_finish || true
