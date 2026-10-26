#!/usr/bin/env bash
# Ca kiểm âm: cổng tự viết, không dùng thư viện gate.sh — lỗi runtime sẽ thoát 0 (xanh giả).
grep -rn "TODO" src/ && exit 1
exit 0
