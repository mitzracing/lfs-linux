#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT_DIR
readonly REPOSITORY="${E2E_GITHUB_REPO:-mitzracing/live-for-speed-linux}"
readonly WORKFLOW='feedback-triage.yml'
RUN_STAMP="$(date -u +%Y%m%d%H%M%S)-$$"
readonly RUN_STAMP
readonly BRANCH="e2e-support-flow-$RUN_STAMP"
TMP_ROOT="$(mktemp -d /tmp/lfs-support-e2e.XXXXXX)"
readonly TMP_ROOT
clean_issue=''
sensitive_issue=''
pull_request=''
branch_created=0

cleanup() {
  set +e
  if [[ -n "$pull_request" ]]; then
    gh pr close "$pull_request" --repo "$REPOSITORY" --comment 'E2E cleanup: linked pull-request flow was verified.' >/dev/null 2>&1
  fi
  if (( branch_created )); then
    gh api --method DELETE "repos/$REPOSITORY/git/refs/heads/$BRANCH" >/dev/null 2>&1
  fi
  if [[ -n "$clean_issue" ]]; then
    gh issue close "$clean_issue" --repo "$REPOSITORY" --reason completed --comment 'E2E cleanup: form handoff, classification, queue visibility, and linked PR were verified.' >/dev/null 2>&1
  fi
  if [[ -n "$sensitive_issue" ]]; then
    gh issue close "$sensitive_issue" --repo "$REPOSITORY" --reason completed --comment 'E2E cleanup: sensitive-report quarantine was verified with synthetic data.' >/dev/null 2>&1
  fi
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

if [[ "${E2E_GITHUB_CONFIRM:-}" != 'yes' ]]; then
  printf 'This test creates and closes public E2E issues and a pull request.\n' >&2
  printf 'Re-run with E2E_GITHUB_CONFIRM=yes after reviewing tests/e2e-github-support.sh.\n' >&2
  exit 2
fi
for command_name in gh node python3 git; do
  command -v "$command_name" >/dev/null
 done
gh auth status >/dev/null

wait_for_issue_run() {
  local title="$1"
  local runs_file="$TMP_ROOT/runs.json"
  local run_id=''
  local attempt
  for ((attempt = 1; attempt <= 60; attempt += 1)); do
    gh run list --repo "$REPOSITORY" --workflow "$WORKFLOW" --event issues --limit 30 \
      --json databaseId,displayTitle,createdAt >"$runs_file"
    run_id="$(python3 - "$runs_file" "$title" <<'PY'
import json
import sys
runs = json.load(open(sys.argv[1], encoding="utf-8"))
match = next((run for run in runs if run["displayTitle"] == sys.argv[2]), None)
print(match["databaseId"] if match else "")
PY
)"
    if [[ -n "$run_id" ]]; then
      timeout --foreground --kill-after=10s 300 gh run watch "$run_id" --repo "$REPOSITORY" --exit-status >/dev/null
      printf '%s\n' "$run_id"
      return 0
    fi
    sleep 2
  done
  printf 'No triage workflow run appeared for %s\n' "$title" >&2
  return 1
}

wait_for_pull_checks() {
  local pull_number="$1"
  local checks_file="$TMP_ROOT/pr-checks.json"
  local count=0
  local attempt
  for ((attempt = 1; attempt <= 60; attempt += 1)); do
    gh pr checks "$pull_number" --repo "$REPOSITORY" --json name >"$checks_file" 2>/dev/null || true
    count="$(python3 - "$checks_file" <<'PY'
import json
import sys
try:
    print(len(json.load(open(sys.argv[1], encoding="utf-8"))))
except (json.JSONDecodeError, OSError):
    print(0)
PY
)"
    if (( count > 0 )); then
      timeout --foreground --kill-after=10s 420 \
        gh pr checks "$pull_number" --repo "$REPOSITORY" --watch --fail-fast >/dev/null
      return 0
    fi
    sleep 2
  done
  printf 'No pull-request checks appeared for #%s\n' "$pull_number" >&2
  return 1
}

assert_issue_labels() {
  local issue_number="$1"
  local mode="$2"
  local issue_file="$TMP_ROOT/issue-$issue_number.json"
  gh issue view "$issue_number" --repo "$REPOSITORY" --json labels,comments,state,url >"$issue_file"
  python3 - "$issue_file" "$mode" <<'PY'
import json
import sys
issue = json.load(open(sys.argv[1], encoding="utf-8"))
mode = sys.argv[2]
labels = {label["name"] for label in issue["labels"]}
if mode == "queue":
    expected = {"type:compatibility", "distro:manjaro", "status:needs-reproduction", "help wanted"}
    assert expected <= labels, (expected, labels)
    assert "status:possible-sensitive" not in labels, labels
    assert any("contributor queue" in comment["body"] for comment in issue["comments"]), issue
else:
    expected = {"type:bug", "status:possible-sensitive", "status:needs-maintainer"}
    assert expected <= labels, (expected, labels)
    assert "help wanted" not in labels, labels
    assert "status:needs-reproduction" not in labels, labels
    assert any("withheld from the contributor queue" in comment["body"] for comment in issue["comments"]), issue
PY
}

node - "$ROOT_DIR/website/feedback.js" "$ROOT_DIR/VERSION" "$RUN_STAMP" >"$TMP_ROOT/handoff.json" <<'NODE'
const feedback = require(process.argv[2]);
const version = require("node:fs").readFileSync(process.argv[3], "utf8").trim();
const runStamp = process.argv[4];
const plan = feedback.buildHandoff({
  kind: "compatibility",
  summary: `Website handoff and contributor flow verification ${runStamp}`,
  distribution: "Manjaro Linux",
  distributionVersion: "Synthetic E2E environment",
  packageMethod: "deterministic source archive",
  wrapperVersion: version,
  desktop: "Headless browser handoff test",
  graphics: "Synthetic E2E fixture; no hardware claim",
  details: "The browser generated a complete compatibility handoff without sending form data to an external service.",
  expected: "The report should enter the sanitized contributor queue.",
  steps: "1. Fill the website form.\n2. Prepare the GitHub handoff.\n3. Review and submit the structured report.",
  value: "Verify the public support workflow.",
  diagnostics: "Synthetic E2E diagnostic: no private data.",
  safety: "confirmed",
});
process.stdout.write(JSON.stringify(plan));
NODE

python3 - "$TMP_ROOT/handoff.json" "$TMP_ROOT/clean-title.txt" "$TMP_ROOT/clean-body.md" <<'PY'
import json
import sys
plan = json.load(open(sys.argv[1], encoding="utf-8"))
fields = plan["fields"]
open(sys.argv[2], "w", encoding="utf-8").write(plan["title"])
body = f"""### Linux distribution

{fields['distribution']}

### Distribution and version

{fields['distributionVersion']}

### Installation method

{fields['packageMethod']}

### Desktop and display session

{fields['desktop']}

### GPU and driver

{fields['graphics']}

### Compatibility result

{fields['details']}

### Package or dependency differences

No differences in this synthetic E2E fixture.

### Reproduction steps

{fields['steps']}

### Sanitized diagnostics

```text
{fields['diagnostics']}
```

### Public-data check

- [x] I removed passwords, unlock codes, account data, registry files, full home paths, and proprietary files.
- [x] I understand that exact Wine and payload pins must not be weakened for distribution compatibility.
"""
open(sys.argv[3], "w", encoding="utf-8").write(body)
PY

clean_title="$(<"$TMP_ROOT/clean-title.txt")"
clean_url="$(gh issue create --repo "$REPOSITORY" --title "$clean_title" --label 'type:compatibility' --body-file "$TMP_ROOT/clean-body.md")"
clean_issue="${clean_url##*/}"
clean_run="$(wait_for_issue_run "$clean_title")"
assert_issue_labels "$clean_issue" queue

gh issue list --repo "$REPOSITORY" --state open \
  --search 'is:issue label:"help wanted" -label:"status:possible-sensitive"' \
  --limit 100 --json number >"$TMP_ROOT/queue.json"
python3 - "$TMP_ROOT/queue.json" "$clean_issue" <<'PY'
import json
import sys
numbers = {item["number"] for item in json.load(open(sys.argv[1], encoding="utf-8"))}
assert int(sys.argv[2]) in numbers, (sys.argv[2], numbers)
PY

main_commit="$(gh api "repos/$REPOSITORY/git/ref/heads/main" --jq '.object.sha')"
main_tree="$(gh api "repos/$REPOSITORY/git/commits/$main_commit" --jq '.tree.sha')"
python3 - "$clean_issue" >"$TMP_ROOT/blob.json" <<'PY'
import json
import sys
print(json.dumps({
    "content": f"Synthetic linked-PR E2E marker for issue #{sys.argv[1]}. This branch is deleted after verification.\n",
    "encoding": "utf-8",
}))
PY
blob_sha="$(gh api --method POST "repos/$REPOSITORY/git/blobs" --input "$TMP_ROOT/blob.json" --jq '.sha')"
python3 - "$main_tree" "$blob_sha" >"$TMP_ROOT/tree.json" <<'PY'
import json
import sys
print(json.dumps({
    "base_tree": sys.argv[1],
    "tree": [{"path": "artifacts/e2e-support-flow.txt", "mode": "100644", "type": "blob", "sha": sys.argv[2]}],
}))
PY
tree_sha="$(gh api --method POST "repos/$REPOSITORY/git/trees" --input "$TMP_ROOT/tree.json" --jq '.sha')"
python3 - "$main_commit" "$tree_sha" >"$TMP_ROOT/commit.json" <<'PY'
import json
import sys
print(json.dumps({
    "message": "test: verify linked support pull request",
    "tree": sys.argv[2],
    "parents": [sys.argv[1]],
}))
PY
commit_sha="$(gh api --method POST "repos/$REPOSITORY/git/commits" --input "$TMP_ROOT/commit.json" --jq '.sha')"
python3 - "$BRANCH" "$commit_sha" >"$TMP_ROOT/ref.json" <<'PY'
import json
import sys
print(json.dumps({"ref": f"refs/heads/{sys.argv[1]}", "sha": sys.argv[2]}))
PY
gh api --method POST "repos/$REPOSITORY/git/refs" --input "$TMP_ROOT/ref.json" >/dev/null
branch_created=1
cat >"$TMP_ROOT/pr-body.md" <<EOF
## User problem

The public support workflow needs proof that contributors can self-select a classified ticket and submit a linked pull request.

Closes #$clean_issue

## Change

Add one synthetic marker on a disposable E2E branch. This pull request will not be merged.

## Verification

- [x] The ticket is visible in the sanitized contributor queue.
- [x] The pull request contains a closing reference.
- [x] The branch will be deleted after verification.

## Runtime boundary

- [x] This synthetic test does not alter the direct launch path.
EOF
pr_url="$(gh pr create --repo "$REPOSITORY" --base main --head "$BRANCH" --title '[E2E] Linked contributor flow verification' --body-file "$TMP_ROOT/pr-body.md")"
pull_request="${pr_url##*/}"
wait_for_pull_checks "$pull_request"
gh pr view "$pull_request" --repo "$REPOSITORY" --json closingIssuesReferences,state,url >"$TMP_ROOT/pr.json"
python3 - "$TMP_ROOT/pr.json" "$clean_issue" <<'PY'
import json
import sys
pull = json.load(open(sys.argv[1], encoding="utf-8"))
references = {item["number"] for item in pull["closingIssuesReferences"]}
assert pull["state"] == "OPEN", pull
assert int(sys.argv[2]) in references, (sys.argv[2], references)
PY
gh pr list --repo "$REPOSITORY" --state open --limit 100 --json number >"$TMP_ROOT/pr-dashboard.json"
python3 - "$TMP_ROOT/pr-dashboard.json" "$pull_request" <<'PY'
import json
import sys
numbers = {item["number"] for item in json.load(open(sys.argv[1], encoding="utf-8"))}
assert int(sys.argv[2]) in numbers, (sys.argv[2], numbers)
PY

gh pr close "$pull_request" --repo "$REPOSITORY" --comment 'E2E passed: self-selection queue, linked issue reference, PR dashboard visibility, and CI were verified.' >/dev/null
gh api --method DELETE "repos/$REPOSITORY/git/refs/heads/$BRANCH" >/dev/null
branch_created=0
pull_request=''

sensitive_title="[E2E] Synthetic sensitive-ticket quarantine verification $RUN_STAMP"
cat >"$TMP_ROOT/sensitive-body.md" <<'EOF'
### Linux distribution

Manjaro Linux

### Distribution version

Synthetic E2E environment

### Wrapper version

__WRAPPER_VERSION__

### Desktop and display session

Synthetic fixture

### GPU and driver

Synthetic fixture

### What happened?

A deliberately synthetic private path reached triage.

### What did you expect?

The issue must be withheld from contributor work.

### Steps to reproduce

1. Submit this marked E2E fixture.
2. Wait for deterministic triage.

### Sanitized diagnostics

```text
/home/example/private-e2e.log
```

### Public-data check

- [x] This is synthetic test data and identifies no person.
- [x] I searched open issues for the same problem.
EOF
python3 - "$TMP_ROOT/sensitive-body.md" "$ROOT_DIR/VERSION" <<'PY'
import pathlib
import sys
body_path = pathlib.Path(sys.argv[1])
version = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8").strip()
body_path.write_text(body_path.read_text(encoding="utf-8").replace("__WRAPPER_VERSION__", version), encoding="utf-8")
PY
sensitive_url="$(gh issue create --repo "$REPOSITORY" --title "$sensitive_title" --label 'type:bug' --body-file "$TMP_ROOT/sensitive-body.md")"
sensitive_issue="${sensitive_url##*/}"
sensitive_run="$(wait_for_issue_run "$sensitive_title")"
assert_issue_labels "$sensitive_issue" quarantine

gh issue list --repo "$REPOSITORY" --state open \
  --search 'is:issue label:"help wanted" -label:"status:possible-sensitive"' \
  --limit 100 --json number >"$TMP_ROOT/queue-after-sensitive.json"
python3 - "$TMP_ROOT/queue-after-sensitive.json" "$sensitive_issue" <<'PY'
import json
import sys
numbers = {item["number"] for item in json.load(open(sys.argv[1], encoding="utf-8"))}
assert int(sys.argv[2]) not in numbers, (sys.argv[2], numbers)
PY

gh issue close "$clean_issue" --repo "$REPOSITORY" --reason completed --comment 'E2E passed: website-generated schema, classification, queue visibility, and linked PR were verified.' >/dev/null
gh issue close "$sensitive_issue" --repo "$REPOSITORY" --reason completed --comment 'E2E passed: synthetic sensitive data was quarantined from contributor work.' >/dev/null
clean_issue=''
sensitive_issue=''

printf 'clean_issue=%s clean_run=https://github.com/%s/actions/runs/%s\n' "$clean_url" "$REPOSITORY" "$clean_run"
printf 'linked_pr=%s\n' "$pr_url"
printf 'sensitive_issue=%s sensitive_run=https://github.com/%s/actions/runs/%s\n' "$sensitive_url" "$REPOSITORY" "$sensitive_run"
printf '[PASS] live GitHub form-schema handoff, deterministic triage, safe queue, linked PR, dashboard, CI, and quarantine E2E\n'
