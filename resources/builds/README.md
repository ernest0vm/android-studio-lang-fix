# Bundled snapshots

Each subdirectory here is named after an Android Studio build number (the
contents of `Contents/Resources/build.txt`, e.g. `AI-261.25134.95.2612.15914620`)
and holds that build's `.lproj` folders.

Nothing is bundled by default, and that is deliberate. Language files are
covered by the app's code signature, so only the exact bytes shipped with a
given build can be restored — files from any other build invalidate the
signature and macOS refuses to launch the app.

Take a snapshot of your own install with `as-langfix --import`. It is written
to `~/.local/share/as-langfix/builds/<build>/`, which `as-langfix` searches
first. Copy one in here only if you have verified it came from that exact
build.
