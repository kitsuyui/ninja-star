#!/usr/bin/env bash
set -euo pipefail
cd "${0%/*}"
coffee='./node_modules/.bin/coffee'
echo '#!/usr/bin/env node' > bin/ninjastar
"$coffee" -sc < bin/ninjastar.coffee >> bin/ninjastar
"$coffee" -sc < index.coffee > index.js
