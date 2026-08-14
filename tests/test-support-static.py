#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
TEMPLATES = ROOT / ".github" / "ISSUE_TEMPLATE"
FORMS = {
    "bug.yml": ("type:bug", {"distribution", "wrapper_version", "problem", "expected", "steps", "safety"}),
    "compatibility.yml": (
        "type:compatibility",
        {"distribution", "distribution_version", "result", "reproduction", "safety"},
    ),
    "feature.yml": ("type:feature", {"problem", "proposal", "value", "area", "boundaries"}),
    "feedback.yml": ("type:feedback", {"experience", "worked", "improve", "safety"}),
}


def load_yaml(path: Path) -> dict:
    value = yaml.safe_load(path.read_text(encoding="utf-8"))
    assert isinstance(value, dict), path
    return value


for filename, (expected_label, required_ids) in FORMS.items():
    path = TEMPLATES / filename
    form = load_yaml(path)
    assert form.get("name"), path
    assert form.get("description"), path
    assert str(form.get("title", "")).startswith("["), path
    assert expected_label in form.get("labels", []), path
    body = form.get("body")
    assert isinstance(body, list) and body, path
    ids = [item.get("id") for item in body if isinstance(item, dict) and item.get("id")]
    assert len(ids) == len(set(ids)), f"duplicate field id in {path}"
    assert required_ids <= set(ids), f"missing required field in {path}: {required_ids - set(ids)}"
    text = path.read_text(encoding="utf-8")
    assert "public" in text.casefold(), f"public-data notice missing in {path}"
    assert "password" in text.casefold() or "credentials" in text.casefold(), path

config = load_yaml(TEMPLATES / "config.yml")
assert config.get("blank_issues_enabled") is False
links = config.get("contact_links")
assert isinstance(links, list) and len(links) >= 2
assert any("security/advisories/new" in str(link.get("url", "")) for link in links)

workflow_path = ROOT / ".github" / "workflows" / "feedback-triage.yml"
load_yaml(workflow_path)
workflow = workflow_path.read_text(encoding="utf-8")
assert "issues:" in workflow and "types: [opened]" in workflow
assert re.search(r"^\s+issues:\s+write\s*$", workflow, re.MULTILINE)
assert "pull_request_target" not in workflow
assert 'triage-feedback.py --apply "$GITHUB_EVENT_PATH"' in workflow
assert "github.event.issue.title" not in workflow and "github.event.issue.body" not in workflow

support = (ROOT / "SUPPORT.md").read_text(encoding="utf-8")
triage = (ROOT / "docs" / "TRIAGE.md").read_text(encoding="utf-8")
website = (ROOT / "website" / "index.html").read_text(encoding="utf-8")
pull_template = (ROOT / ".github" / "PULL_REQUEST_TEMPLATE.md").read_text(encoding="utf-8")

for filename in FORMS:
    expected = f"issues/new?template={filename}"
    assert expected in support, expected
    assert expected in website, expected
assert "GitHub account is required" in support
assert "GitHub sign-in is required" in website
assert 'label%3A%22help+wanted%22' in support
assert 'label%3A%22help+wanted%22' in triage
assert "Closes #NUMBER" in support and "Closes #NUMBER" in triage
assert "Closes #" in pull_template
assert "scheduled" in triage.casefold()

print("[PASS] support forms, public-data boundaries, contributor queue, and triage workflow are structurally valid")
