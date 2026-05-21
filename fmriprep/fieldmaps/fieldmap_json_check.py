#!/usr/bin/env python3

import json
import re
import sys
from pathlib import Path

pattern = re.compile(
    r"^ses-[^/]+/(func|dwi)/sub-[^/]+_ses-[^/]+_.*_(bold|dwi)\.nii\.gz$"
)

json_file = Path(sys.argv[1])

try:
    data = json.loads(json_file.read_text())
    intended = data.get("IntendedFor")

    if isinstance(intended, str):
        intended = [intended]

    ok = (
        isinstance(intended, list)
        and len(intended) > 0
        and all(isinstance(x, str) and pattern.match(x) for x in intended)
    )

    if not ok:
        print(json_file)
        sys.exit(1)

except Exception:
    print(json_file)
    sys.exit(1)

sys.exit(0)
