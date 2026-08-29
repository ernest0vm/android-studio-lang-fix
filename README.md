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
shipped with *your installed build* will re-seal the bundle. That is why this
tool restores from a snapshot of your own healthy install, keyed by build
number, and verifies the signature afterwards — rolling the change back if it
would leave the app unlaunchable.

## Install

```bash
brew tap ernest0vm/langfix https://github.com/ernest0vm/android-studio-lang-fix
```

```bash
brew install as-langfix
```

## Usage

**Right after installing or updating Android Studio**, while the app is still
intact, take a snapshot:

```bash
as-langfix --import
```

Later, once a cleanup tool has deleted the files and an update refuses to
apply, restore them:

```bash
as-langfix
```

Then retry the update from Android Studio.

Other commands:

```bash
as-langfix --check    # report status and signature validity; change nothing
as-langfix --list     # list available snapshots
as-langfix --app "/Applications/Android Studio Preview.app"   # other bundle
```

Snapshots live in `~/.local/share/as-langfix/builds/<build>/`. Each Android
Studio update produces a new build number, so re-run `--import` after every
update — otherwise there is nothing to restore from the next time.

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
as-langfix --import
```

Versions before v2.0.0 of this tool caused exactly this by shipping one static
copy of the files and writing it into any install. v2 restores only bytes that
match your installed build, and rolls back rather than leaving the app in this
state.

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

1. Push and tag, e.g. `v2.0.0`.
2. Compute the tarball hash:
   ```bash
   curl -sL https://github.com/ernest0vm/android-studio-lang-fix/archive/refs/tags/v2.0.0.tar.gz | shasum -a 256
   ```
3. Put that hash and the new URL in `Formula/as-langfix.rb`.

## License

MIT
