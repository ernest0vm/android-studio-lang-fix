class AsLangfix < Formula
  desc "Restore Asian .lproj files deleted from Android Studio so patch updates work"
  homepage "https://github.com/ernest0vm/android-studio-lang-fix"
  url "https://github.com/ernest0vm/android-studio-lang-fix/archive/refs/tags/v2.2.0.tar.gz"
  sha256 "2b513437c9a025338f0799dfd91113960ab9d164ed8c722dc4ef4b216bb36c58"
  license "MIT"
  head "https://github.com/ernest0vm/android-studio-lang-fix.git", branch: "main"

  def install
    bin.install "bin/as-langfix"
    pkgshare.install "resources"
  end

  test do
    assert_match "Usage", shell_output("#{bin}/as-langfix --help")
  end
end
