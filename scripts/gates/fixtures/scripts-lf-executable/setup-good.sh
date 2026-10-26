#!/usr/bin/env bash
# Ca xanh: .gitattributes ép LF; scripts/chay.sh LF và mode 100755 trong index.
set -e
d="$(mktemp -d)"
cd "$d"
git init -q
git config core.autocrlf false
mkdir -p scripts
printf '* text=auto eol=lf\n*.sh text eol=lf\n' > .gitattributes
printf '#!/usr/bin/env bash\necho chay\n' > scripts/chay.sh
git add .gitattributes scripts/chay.sh
git update-index --chmod=+x scripts/chay.sh
pwd
