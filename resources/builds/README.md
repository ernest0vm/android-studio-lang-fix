# Bundled snapshots

Each subdirectory is named after an Android Studio build number — the contents
of `Contents/Resources/build.txt`, e.g. `AI-261.26222.65.2613.15948027` — and
holds that build's `.lproj` folders.

`as-langfix` searches your own snapshots first
(`~/.local/share/as-langfix/builds/`) and falls back to these. They exist so a
build that has been captured once is recoverable on any machine, including one
where the files were already deleted before the tool was ever installed.

## Why shipping these is safe

A file here is never trusted on its own. Before writing anything,
`as-langfix` reads the expected SHA-256 out of the code signature of the
Android Studio install in front of it, and copies the file **only if its hash
already matches**. A snapshot that is wrong, stale, or tampered with simply
fails that check and is refused — it cannot be installed, and it cannot break
a signature.

You can confirm that yourself: alter any file here, then run `as-langfix`. It
will report `(no matching snapshot)` and write nothing.

## Contributing a build

On a healthy install of a build that is not listed here:

```bash
as-langfix --import
as-langfix --export /path/to/this/repo/resources/builds
```

Then open a pull request. Only import from an install whose signature is
valid — `--import` enforces this and refuses otherwise, so a snapshot in a PR
is verifiable by construction.

## Attribution

These files are verbatim resources from Android Studio, © Google LLC and
JetBrains s.r.o., redistributed here solely so a damaged installation can be
repaired with its own original bytes. Android Studio is distributed under the
Apache License 2.0. They are a few kilobytes of macOS localization strings —
permission-prompt text and the Finder "Get Info" string — and are useless
outside of repairing the exact build they came from.
