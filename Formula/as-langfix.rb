class AsLangfix < Formula
  desc "Restore Asian .lproj files deleted from Android Studio so patch updates work"
  homepage "https://github.com/ernest0vm/android-studio-lang-fix"
  url "https://github.com/ernest0vm/android-studio-lang-fix/archive/refs/tags/v1.0.2.tar.gz"
  sha256 "e8f7bc8835ff220f08a6b87fa04fe1465ab42738bd6dc3a77397ab502a6cd3de"
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
