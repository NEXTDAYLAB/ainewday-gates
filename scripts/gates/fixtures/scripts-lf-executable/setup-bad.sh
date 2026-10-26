#!/usr/bin/env bash
# Ca kiểm âm: repo git tạm KHÔNG có .gitattributes; scripts/chay.sh mang CRLF và mode 100644 trong index.
set -e
d="$(mktemp -d)"
cd "$d"
git init -q
git config core.autocrlf false
mkdir -p scripts
printf '#!/usr/bin/env bash\r\necho chay\r\n' > scripts/chay.sh
git add scripts/chay.sh
git update-index --chmod=-x scripts/chay.sh
pwd
