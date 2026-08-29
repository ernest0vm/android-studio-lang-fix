# android-studio-lang-fix

Restores the Asian language files (`ja.lproj`, `ko.lproj`, `zh-Hans.lproj`,
`zh-Hant.lproj`) that cleanup tools — notably **CleanMyMac X's "Language
Files" cleanup** — delete from `Android Studio.app`. Without them, JetBrains
patch updates abort with conflicts like:

```
Contents/Resources/ja.lproj/InfoPlist.strings   Update   Absent   -
```

## Why this happens

The JetBrains patcher validates every file of the installed version before
applying a patch. If a `.lproj` file was deleted after installation, the
patcher reports it as `Absent` with no solution and refuses to run. This tool
puts the four tiny `InfoPlist.strings` files back so the patch can apply.

> Tip: the permanent fix is to tell CleanMyMac to ignore language files
> (Preferences → Ignore List → System Junk → check "Language files"), or to
> exclude Android Studio from cleanups. This CLI is the quick repair when it
> already happened.

## Install (Homebrew)

```bash
brew tap ernest0vm/langfix https://github.com/ernest0vm/android-studio-lang-fix
brew install as-langfix
```

## Usage

```bash
as-langfix            # restore missing/modified language files
as-langfix --check    # dry run: report OK / MISSING / MODIFIED, change nothing
as-langfix --app "/Applications/Android Studio Preview.app"   # other bundle
```

Run it, then retry the update from Android Studio.

## Troubleshooting: "Operation not permitted"

On macOS Ventura and later, the **App Management** privacy protection blocks
modifying another app's bundle — even with `sudo`. Grant the permission once:

1. Open **System Settings → Privacy & Security → App Management**
2. Enable your terminal app (Terminal, iTerm, etc.)
3. Restart the terminal and run `as-langfix` again (no `sudo` needed)

## Keeping the bundled files up to date

After a successful update, run `as-langfix --check`. If it reports `MODIFIED`,
the new Android Studio version changed the strings: copy them from the app
back into `resources/` in this repo, tag a new release, and bump the formula.

```bash
for l in ja ko zh-Hans zh-Hant; do
  cp "/Applications/Android Studio.app/Contents/Resources/$l.lproj/InfoPlist.strings" "resources/$l.lproj/"
done
```

## Releasing

1. Push the repo to GitHub and create a tag, e.g. `v1.0.0`.
2. Compute the tarball hash:
   ```bash
   curl -sL https://github.com/ernest0vm/android-studio-lang-fix/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
   ```
3. Put that hash in `Formula/as-langfix.rb` (`sha256 "..."`).

Until you cut a release you can install straight from `main`:

```bash
brew install --HEAD ernest0vm/langfix/as-langfix
```
