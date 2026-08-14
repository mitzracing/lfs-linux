# GitHub Support Queue

## Purpose

The queue converts player reports into contributor work without manual assignment. GitHub Issues stores tickets. GitHub Actions applies deterministic labels and guidance.

No external support service, feedback database, scheduled worker, or anonymous submission token exists.

## Live dashboards

- [Pull requests to review](https://github.com/mitzracing/live-for-speed-linux/pulls?q=is%3Apr+is%3Aopen)
- [Maintainer decisions](https://github.com/mitzracing/live-for-speed-linux/issues?q=is%3Aissue+is%3Aopen+label%3A%22status%3Aneeds-maintainer%22)
- [Contributor queue](https://github.com/mitzracing/live-for-speed-linux/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22+-label%3A%22status%3Apossible-sensitive%22)
- [Reports that need reproduction](https://github.com/mitzracing/live-for-speed-linux/issues?q=is%3Aissue+is%3Aopen+label%3A%22status%3Aneeds-reproduction%22+-label%3A%22status%3Apossible-sensitive%22)
- [Possible sensitive data](https://github.com/mitzracing/live-for-speed-linux/issues?q=is%3Aissue+is%3Aopen+label%3A%22status%3Apossible-sensitive%22)

These searches are the maintainer dashboard. They stay current without a scheduled digest issue.

## Automatic classification

| Ticket type | Automatic state | Contributor action |
|---|---|---|
| Bug | `status:needs-reproduction`, `help wanted` | Reproduce, comment, then submit a focused fix |
| Compatibility | `status:needs-reproduction`, `help wanted` | Confirm on that distribution, then improve packaging or docs |
| Feature | `status:needs-maintainer` | Wait for scope approval |
| Feedback | `status:needs-maintainer` | Wait for a maintainer decision |
| Unknown | `status:needs-maintainer` | Wait for classification |
| Any suspected-sensitive report | `status:possible-sensitive`, `status:needs-maintainer` | Do not open or continue contributor work |

Distribution forms also receive an Arch, Manjaro, or other-distribution label. Known credential, identity, home-path, and registry patterns add `status:possible-sensitive` and `status:needs-maintainer`. Sensitive reports do not receive `help wanted` or `status:needs-reproduction`; opening or editing a report also removes those labels if they are present. Editing out the text does not clear quarantine automatically. A maintainer must review the public history first.

## Contributor pull workflow

1. Open the [sanitized contributor queue](https://github.com/mitzracing/live-for-speed-linux/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22+-label%3A%22status%3Apossible-sensitive%22).
2. Reproduce the report.
3. Comment that you plan to work on it. No maintainer assignment is required.
4. Keep the change inside the wrapper boundary.
5. Add focused tests.
6. Open a pull request with `Closes #NUMBER`.
7. Wait for CI and maintainer review.

Feature proposals must receive maintainer approval before implementation.

## Maintainer routine

Run this routine a few times each week:

1. Review open pull requests and CI results.
2. Decide tickets with `status:needs-maintainer`.
3. Review `status:possible-sensitive` immediately and ask the author to remove exposed data.
4. Close spam, duplicates, and reports that cannot be reproduced.

Maintainers do not assign routine contributor work. Contributors self-select from `help wanted`.

## Failure and recovery

Issue forms apply the type label before automation runs. If the triage workflow fails, the ticket remains available with its original type label. Re-run the failed workflow or apply the documented state label manually.

Disable `.github/workflows/feedback-triage.yml` to stop automation. Removing that workflow does not remove or change existing tickets.
