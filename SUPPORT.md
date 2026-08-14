# Help and Feedback

Live for Speed Linux uses GitHub Issues as its public support queue. No programming knowledge is required.

A GitHub account is required because this project uses no feedback server, contact database, or third-party form service.

The [website feedback generator](https://mitzracing.github.io/live-for-speed-linux/#support) keeps text in your browser, removes known sensitive-data patterns, and opens the matching GitHub Issue Form with the safe text filled in. You review the result and submit it on GitHub. The page does not save or transmit form text itself.

## Choose a report

- [Game or launcher problem](https://github.com/mitzracing/live-for-speed-linux/issues/new?template=bug.yml)
- [Distribution compatibility report](https://github.com/mitzracing/live-for-speed-linux/issues/new?template=compatibility.yml)
- [Feature request](https://github.com/mitzracing/live-for-speed-linux/issues/new?template=feature.yml)
- [General player feedback](https://github.com/mitzracing/live-for-speed-linux/issues/new?template=feedback.yml)

The forms ask for plain-language information. They do not require code, patches, or developer tools.

## Public-data boundary

All issue reports are public. The browser generator redacts known credentials, private keys, email addresses, machine identifiers, complete Linux, macOS, and Windows home paths, and registry dumps. Pattern matching cannot identify every private value. Before submission, review the generated text and remove:

- passwords, unlock codes, and account data
- complete home-directory paths
- Wine registry files
- proprietary game files and screenshots that contain private data
- access tokens, cookies, and private keys

Use [private vulnerability reporting](https://github.com/mitzracing/live-for-speed-linux/security/advisories/new) for sensitive security problems.

## What happens next

GitHub automation classifies each ticket. Reproducible bugs and compatibility work enter the [sanitized contributor queue](https://github.com/mitzracing/live-for-speed-linux/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22+-label%3A%22status%3Apossible-sensitive%22) with the `help wanted` label. Feature requests wait for a maintainer scope decision. A report with a known sensitive-data pattern is withheld from contributor work until a maintainer confirms that its public text is safe.

Contributors select work from the queue, comment before implementation, and submit a pull request with `Closes #NUMBER`. Maintainers review decisions and pull requests a few times each week. No response-time guarantee applies.

This community project is not official Live for Speed support.
