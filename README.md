# android-studio-lang-fix

Restores the language files (`ja.lproj`, `ko.lproj`, `zh-Hans.lproj`,
`zh-Hant.lproj`) that cleanup tools — notably **CleanMyMac X's "Language
Files" cleanup** — delete from `Android Studio.app`. Without them, JetBrains
patch updates abort with conflicts like:

```
Contents/Resources/ja.lproj/InfoPlist.strings   Update   Absent   -
```

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

This tool repairs the damage; it does not prevent it. Tell your cleanup tool to
leave language files alone:

**CleanMyMac X** → Settings → Ignore List → System Junk → enable **Language
files** (or add Android Studio to the ignore list).

## Troubleshooting

### "Operation not permitted"

On macOS Ventura and later, the **App Management** privacy protection blocks
modifying another app's bundle — even with `sudo`. Grant the permission once:

1. Open **System Settings → Privacy & Security → App Management**
2. Enable your terminal app (Terminal, iTerm, etc.); add it with **+** if it is
   not listed
3. Fully quit the terminal (**Cmd+Q**), reopen it, and run `as-langfix` again —
   no `sudo` needed

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
