class AsLangfix < Formula
  desc "Restore Asian .lproj files deleted from Android Studio so patch updates work"
  homepage "https://github.com/ernest0vm/android-studio-lang-fix"
  url "https://github.com/ernest0vm/android-studio-lang-fix/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "7cb5c693ff2e2c77b7e53d99128825f25e38b9f1a54a49220324cb775329f81c"
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
