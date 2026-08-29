class AsLangfix < Formula
  desc "Restore Asian .lproj files deleted from Android Studio so patch updates work"
  homepage "https://github.com/ernest0vm/android-studio-lang-fix"
  url "https://github.com/ernest0vm/android-studio-lang-fix/archive/refs/tags/v2.1.0.tar.gz"
  sha256 "7a6c17062b46596f6593fe7b7f1328adcf4668e0f2f552ead13d254214002825"
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
