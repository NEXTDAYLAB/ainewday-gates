#!/usr/bin/env bash
# Ca kiểm âm: cổng không có thư mục fixtures/khong-ca-am/.
source "$(dirname "$0")/lib/gate.sh"
gate_init "khong-ca-am" "$@"
gate_finish
