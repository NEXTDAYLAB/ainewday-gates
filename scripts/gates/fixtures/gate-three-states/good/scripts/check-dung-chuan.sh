#!/usr/bin/env bash
# Ca xanh: dùng thư viện, đủ gate_init + gate_finish.
source "$(dirname "$0")/lib/gate.sh"
gate_init "dung-chuan" "$@"
gate_finish
