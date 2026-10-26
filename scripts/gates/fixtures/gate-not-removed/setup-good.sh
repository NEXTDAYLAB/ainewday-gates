#!/usr/bin/env bash
# Dựng repo git tạm: gốc (nhánh base) có 2 cổng a, b; nhánh hiện tại xoá cổng b.
# Ca xanh: xoá b CÓ khai lý do ở mục "Cổng đã gỡ".
# In ra đường dẫn repo; test-gates.sh chạy cổng trong đó rồi xoá.
set -e
d="$(mktemp -d)"
cd "$d"
git init -q
git config user.email fixture@example.invalid
git config user.name fixture
git config core.autocrlf false
mkdir -p scripts docs
printf '#!/usr/bin/env bash\n' > scripts/check-a.sh
printf '#!/usr/bin/env bash\n' > scripts/check-b.sh
printf '# GATES\n\n| `a` | x | ✅ |\n| `b` | y | ✅ |\n\n## Z. Cổng đã gỡ\n\n' > docs/GATES.md
git add -A && git commit -qm goc
git branch base
git rm -q scripts/check-b.sh
printf '# GATES\n\n| `a` | x | ✅ |\n\n## Z. Cổng đã gỡ\n\n' > docs/GATES.md
printf -- '- `b` — gỡ 26/10/2026: trùng với cổng a \n' >> docs/GATES.md
git add -A && git commit -qm "go cong b"
pwd
