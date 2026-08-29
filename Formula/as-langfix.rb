class AsLangfix < Formula
  desc "Restore Asian .lproj files deleted from Android Studio so patch updates work"
  homepage "https://github.com/ernest0vm/android-studio-lang-fix"
  url "https://github.com/ernest0vm/android-studio-lang-fix/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "915f1ff016054cc60b8078902e0d1230218e7505d1ae6097da0356312929bc78"
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
