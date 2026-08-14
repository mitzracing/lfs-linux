#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT_DIR
readonly HTML="$ROOT_DIR/website/index.html"
readonly CSS="$ROOT_DIR/website/styles.css"

[[ -f "$HTML" && -f "$CSS" ]]
(( $(stat -c %s "$HTML") < 102400 ))
(( $(stat -c %s "$CSS") < 102400 ))

python3 - "$HTML" <<'PY'
from html.parser import HTMLParser
from pathlib import Path
import sys

class Audit(HTMLParser):
    def __init__(self):
        super().__init__()
        self.h1 = 0
        self.title = 0
        self.viewport = 0
        self.scripts = 0
        self.images = []
        self.ids = set()
        self.links = []
    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == "h1": self.h1 += 1
        if tag == "title": self.title += 1
        if tag == "meta" and values.get("name") == "viewport": self.viewport += 1
        if tag == "script": self.scripts += 1
        if tag == "img": self.images.append(values.get("src", ""))
        if "id" in values: self.ids.add(values["id"])
        if tag == "a": self.links.append(values.get("href", ""))

audit = Audit()
text = Path(sys.argv[1]).read_text()
audit.feed(text)
assert audit.h1 == 1, audit.h1
assert audit.title == 1, audit.title
assert audit.viewport == 1, audit.viewport
assert audit.scripts == 0, audit.scripts
assert set(audit.images) == {"icon.svg"}, audit.images
assert {"top", "install", "trust"} <= audit.ids, audit.ids
assert all(link.startswith(("#", "https://")) for link in audit.links), audit.links
assert "not affiliated with or endorsed" in text
assert "No game binaries" in text
assert "lfs.net" not in " ".join(audit.images)
PY

[[ "$(grep -o '{' "$CSS" | wc -l)" -eq "$(grep -o '}' "$CSS" | wc -l)" ]]
grep -Fq '@media (max-width: 760px)' "$CSS"
grep -Fq 'prefers-reduced-motion' "$CSS"

printf '[PASS] website is small, responsive, script-free, and uses only community-owned imagery\n'
