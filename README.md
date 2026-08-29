# android-studio-lang-fix

Restores the language files (`ja.lproj`, `ko.lproj`, `zh-Hans.lproj`,
`zh-Hant.lproj`) that cleanup tools delete from `Android Studio.app`. Without
them, JetBrains patch updates abort with:

```
Some conflicts were found in the installation area.
Some conflicts below do not have a solution, so the patch cannot be applied.

Contents/Resources/ja.lproj/InfoPlist.strings   Update   Absent   -
```

## Where the deletion comes from

**CleanMyMac X's Smart Scan.** Not a language cleanup you went looking for —
the one-click scan removes unused `.lproj` folders as part of System Junk,
which is why it recurs silently and across every Mac you run it on.

It is recorded in CleanMyMac's own log. On an affected machine:

```bash
grep -h 'remove file.*lproj' ~/Library/Logs/com.macpaw.CleanMyMac4/*.log | grep -i 'Android Studio'
```

```
[Smart Scan]: [remove file] removed at path: /Applications/Android Studio.app/Contents/Resources/ja.lproj
[Smart Scan]: [remove file] removed at path: /Applications/Android Studio.app/Contents/Resources/zh-Hans.lproj
[Smart Scan]: [remove file] removed at path: /Applications/Android Studio.app/Contents/Resources/zh-Hant.lproj
[Smart Scan]: [remove file] removed at path: /Applications/Android Studio.app/Contents/Resources/ko.lproj
```

Only non-English locales go; `en.lproj` — the system language — is kept. Drop
the `grep -i 'Android Studio'` and you will typically see thousands of
removals across every app on the disk.

**Yet Android Studio is the only one that breaks**, for two reasons:

- Deleting these files does not invalidate an app's code signature (see
  below), so nothing else notices.
- Most apps update by replacing the whole bundle. JetBrains IDEs update by
  applying a *patch*, and the patcher refuses to run unless every file it
  intends to touch is present and byte-for-byte what it expects.

So there is no need to stop cleaning language files in general. Excluding the
JetBrains IDEs is enough — see [The real fix](#the-real-fix-stop-the-deletion).

## How it works, and why it works this way

Language files are covered by the app's **code signature**. In the signature's
resource seal they are marked `optional`, which has two consequences worth
understanding:

- **Deleting them keeps the signature valid.** Android Studio still launches,
  which is why the damage goes unnoticed — until an update fails.
- **Replacing them with different bytes makes the signature invalid.** macOS
  then kills the app at launch with `Taskgated Invalid Signature`, and the only
  repair is a full reinstall.

So the files cannot be restored from a generic copy: only the exact bytes
shipped with *your installed build* will re-seal the bundle.

And every build really is different, because each file stamps the build number
into its own first line:

```bash
grep -o 'AI-[0-9.]*' "/Applications/Android Studio.app/Contents/Resources/en.lproj/InfoPlist.strings"
```

That is why a snapshot is per-version, and why no shared archive of these files
can exist. It also gives you a quick way to spot a bad restore: if the
non-English files report a different build than `en.lproj`, they came from
another version.

The signature seal records the expected SHA-256 of every one of these files, so
this tool reads the seal, and **writes a file only when its hash already
matches what the seal demands**. Wrong bytes are never written in the first
place.

### The JetBrains language pack plugins do not help

The Japanese/Korean/Chinese *Language Pack* plugins on the JetBrains
Marketplace localize the IDE's own interface — menus, settings, inspections —
and load at runtime from the plugins directory.

These `.lproj` files are macOS bundle resources, read by macOS rather than by
the IDE. They hold the strings the system shows in permission prompts
(`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, …) and in Finder's
Get Info panel. Different layer, different format, and build-stamped and
signature-sealed besides. No plugin or third-party copy can substitute for
them.

## Install

```bash
brew tap ernest0vm/langfix https://github.com/ernest0vm/android-studio-lang-fix
```

```bash
brew install as-langfix
```

## Usage

Since every build needs its own snapshot, let the tool take them for you. Run
this once, on a healthy install:

```bash
as-langfix --auto
```

It installs a LaunchAgent that snapshots at login and every six hours, so each
new build is captured shortly after you update — long before a cleanup runs.
Snapshots are skipped when one already exists, so it is a no-op almost always.
Turn it off with `as-langfix --auto off`.

Prefer to do it by hand? Then run this **right after installing or updating
Android Studio**, while the app is still intact:

```bash
as-langfix --import
```

Either way, once a cleanup tool has deleted the files and an update refuses to
apply, restore them:

```bash
as-langfix
```

Then retry the update from Android Studio.

Other commands:

```bash
as-langfix --check    # report status and signature validity; change nothing
as-langfix --list     # list stored snapshots
as-langfix --app "/Applications/Android Studio Preview.app"   # other bundle
```

Snapshots live in `~/.local/share/as-langfix/builds/<build>/`. Importing is
refused if the install is already missing files, so a snapshot is never a
partial one that only looks like protection.

### Snapshots shipped with the tool

A few builds are captured in this repository under
[`resources/builds/`](resources/builds), and `as-langfix` falls back to them
when you have no snapshot of your own for the installed build — which is the
one case the tool otherwise cannot help with.

Trusting them costs nothing: a file is copied only when its SHA-256 already
matches the seal of *your* install, so a snapshot that is wrong or tampered
with is refused rather than applied. Try it — alter one and run `as-langfix`;
it reports `(no matching snapshot)` and writes nothing.

To contribute the build you are running:

```bash
as-langfix --import
as-langfix --export /path/to/repo/resources/builds
```

`--export` moves rather than copies: once a snapshot is safely in the
destination it is removed from your store, so the same build never exists in
two places. Re-exporting a build already there replaces it instead of
duplicating it, and says whether it was `unchanged` or `updated`.

Or skip the two steps entirely and snapshot straight into a checkout, leaving
nothing in your home directory:

```bash
as-langfix --store /path/to/repo/resources/builds --import
```

Export `AS_LANGFIX_STORE` in your shell profile to make that the default.

## The real fix: stop the deletion

This tool repairs the damage; it does not prevent it.

You do not have to give up cleaning language files everywhere — the deletion is
harmless for every app that does not use a patch-based updater. Exclude just
the IDEs:

**CleanMyMac X** → Settings → Ignore List → System Junk → add
`Android Studio.app`, plus any other JetBrains IDE you have installed
(IntelliJ IDEA, WebStorm, PyCharm, GoLand, Rider…). They all ship the same
patch updater and fail the same way.

Do this on every Mac you run the cleaner on — the setting is per-machine.

## Troubleshooting

### "Operation not permitted"

On macOS Ventura and later, the **App Management** privacy protection blocks
modifying another app's bundle — even with `sudo`. Grant the permission once:

1. Open **System Settings → Privacy & Security → App Management**
2. Enable your terminal app (Terminal, iTerm, etc.); add it with **+** if it is
   not listed
3. Fully quit the terminal (**Cmd+Q**), reopen it, and run `as-langfix` again —
   no `sudo` needed

### The update dialog says `Modified` instead of `Absent`

```
Contents/Resources/ja.lproj/InfoPlist.strings   Update   Modified   -
```

The files are present, but their contents are not what this build shipped —
someone restored them from a different version. This is worse than `Absent`:
the patch still refuses, *and* the app's code signature is now invalid.

There is no local recovery. The original bytes exist only in the installer for
your exact build, and a JetBrains patch file contains only the new bytes, not
the old ones. Download the current version from
[developer.android.com/studio](https://developer.android.com/studio) and
install it from scratch — which is what the dialog itself recommends — then
immediately run:

```bash
as-langfix --auto
```

Versions before v2.0.0 of this tool caused exactly this by shipping one static
copy of the files and writing it into any install. Since v2 every byte is
checked against the signature seal before it is written, so a mismatched file
is refused rather than installed.

### "no snapshot for build ..."

There is no snapshot of that exact build to restore from. If the app is still
healthy, run `as-langfix --import` now. If the files are already gone, the
bytes are unrecoverable locally: reinstall Android Studio from the official
installer, then import immediately.

### Android Studio is already crashing at launch

If the app was killed with `Taskgated Invalid Signature`, its signature is
broken and no file copy will fix it. Reinstall from the official installer,
then run `as-langfix --import`. Confirm the state with:

```bash
codesign --verify --verbose=2 "/Applications/Android Studio.app"
```

## Releasing

The formula pins a release tarball by hash, so the tag has to exist before the
formula can point at it. That makes it two commits: the change, then the bump.

```bash
VERSION=2.3.0
```

1. Commit and push the change itself.

2. Cut the release — this creates the tag:

   ```bash
   gh release create "v$VERSION" --title "v$VERSION" --notes "..."
   ```

3. Hash the tarball GitHub generated for that tag:

   ```bash
   curl -sL "https://github.com/ernest0vm/android-studio-lang-fix/archive/refs/tags/v$VERSION.tar.gz" | shasum -a 256
   ```

4. Put the new `url` and `sha256` in `Formula/as-langfix.rb`, then commit and
   push that as its own change.

Installs pick it up with:

```bash
brew update && brew upgrade as-langfix
```

Verify against a real install before releasing — `bash -n bin/as-langfix`
catches only syntax. The paths worth exercising are a restore that succeeds, a
snapshot that does not match the build (must refuse and write nothing), and an
import from an install that is already missing files (must refuse). An ad-hoc
signed throwaway `.app` with a `build.txt` and a couple of `.lproj` folders is
enough to drive all three.

## License

The tool is MIT — see [LICENSE](LICENSE).

The snapshots under [`resources/builds/`](resources/builds) are not covered by
it: they are verbatim Android Studio resources, © Google LLC and JetBrains
s.r.o., included so a damaged install can be repaired with its own original
bytes. See [resources/builds/README.md](resources/builds/README.md).
