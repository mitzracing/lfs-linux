#!/usr/bin/env node
import assert from "node:assert/strict";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const feedback = require("../website/feedback.js");

function baseValues(kind = "compatibility") {
  return {
    kind,
    summary: "Clean distribution verification",
    distribution: "Manjaro Linux",
    distributionVersion: "Manjaro 26.0",
    packageMethod: "source archive",
    wrapperVersion: "0.1.6",
    desktop: "KDE Plasma 6 on X11",
    graphics: "NVIDIA RTX 3070, driver 580.82",
    details: "Setup completed and the game reached the main menu.",
    expected: "The documented setup should work without changed runtime pins.",
    steps: "1. Install the wrapper.\n2. Run lfs-linux setup.\n3. Open the game.",
    value: "Players can verify support on another distribution.",
    diagnostics: "Doctor summary: 0 failure(s)",
    safety: "confirmed",
  };
}

const sensitiveExamples = [
  ["access token", "token=abcdefghijklmnopqrstuvwxyz0123456789"],
  ["private key", "-----BEGIN " + "PRIVATE KEY-----\nnot-a-key\n-----END PRIVATE KEY-----"],
  ["Linux home", "/home/alice/.local/share/lfs-linux/private.log"],
  ["macOS home", "/Users/alice/Library/Application Support/LFS/private.log"],
  ["Windows home", "C:\\Users\\Alice\\AppData\\Local\\LFS\\private.log"],
  ["email", "alice@example.invalid"],
  ["machine identifier", "machine-id=0123456789abcdef"],
  ["registry", "WINE REGISTRY Version 2\n[HKEY_CURRENT_USER\\Software\\LFS]"],
];
for (const [name, source] of sensitiveExamples) {
  const result = feedback.sanitizeText(source);
  assert.ok(result.categories.length > 0, `${name} was not classified`);
  assert.ok(!result.value.includes(source), `${name} was not removed`);
}

const compatibility = feedback.buildHandoff({
  ...baseValues(),
  diagnostics: "Log: /home/alice/.local/state/lfs-linux/latest.log\nemail=alice@example.invalid\ntoken=abcdefghijklmnopqrstuvwxyz0123456789",
});
const compatibilityUrl = new URL(compatibility.url);
assert.equal(compatibilityUrl.origin, "https://github.com");
assert.equal(compatibilityUrl.pathname, "/mitzracing/live-for-speed-linux/issues/new");
assert.equal(compatibilityUrl.searchParams.get("template"), "compatibility.yml");
for (const field of [
  "title",
  "distribution",
  "distribution_version",
  "package_method",
  "desktop",
  "graphics",
  "result",
  "reproduction",
  "diagnostics",
]) {
  assert.ok(compatibilityUrl.searchParams.get(field), `missing compatibility field: ${field}`);
}
assert.ok(!decodeURIComponent(compatibility.url).includes("/home/alice"));
assert.ok(!decodeURIComponent(compatibility.url).includes("alice@example.invalid"));
assert.deepEqual(compatibility.redactions, ["Linux or macOS home path", "credential value", "email address"]);

const bug = feedback.buildHandoff({ ...baseValues("bug"), packageMethod: "" });
assert.equal(new URL(bug.url).searchParams.get("template"), "bug.yml");
assert.equal(new URL(bug.url).searchParams.get("problem"), baseValues().details);

const feature = feedback.buildHandoff({
  ...baseValues("feature"),
  distribution: "",
  distributionVersion: "",
  desktop: "",
  graphics: "",
});
assert.equal(new URL(feature.url).searchParams.get("template"), "feature.yml");
assert.equal(new URL(feature.url).searchParams.get("proposal"), baseValues().expected);
assert.equal(new URL(feature.url).searchParams.get("value"), baseValues().value);

const playerFeedback = feedback.buildHandoff({ ...baseValues("feedback") });
assert.equal(new URL(playerFeedback.url).searchParams.get("template"), "feedback.yml");
assert.match(new URL(playerFeedback.url).searchParams.get("environment"), /Manjaro.*KDE.*NVIDIA/);

assert.throws(
  () => feedback.buildHandoff({ ...baseValues(), safety: "" }),
  /public-data check/,
);
assert.throws(
  () => feedback.buildHandoff({ ...baseValues(), details: "" }),
  /required field/,
);
assert.throws(
  () => feedback.buildHandoff({ ...baseValues(), diagnostics: "x".repeat(9000) }),
  /too long/,
);

console.log("[PASS] browser feedback generator sanitizes private data and maps all report types to GitHub Issue Forms");
