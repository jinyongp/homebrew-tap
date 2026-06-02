class Dotfiles < Formula
  desc "Personal dotfiles and installer"
  homepage "https://github.com/jinyongp/dotfiles"
  url "https://github.com/jinyongp/dotfiles/archive/1facdfe9356adb98125473257981775802598997.tar.gz"
  version "1facdfe9356a"
  sha256 "53eda21236bb353b487717d1a8426ff4e215c70d577e6f025b488876462409cb"
  license :cannot_represent

  def install
    prefix.install Dir["*"]
    prefix.install Dir[".[!.]*"].reject { |path| File.basename(path) == ".git" }
    bin.write_exec_script opt_prefix/"cmd/dotfiles"
  end

  test do
    assert_match "COMMANDS", shell_output("#{bin}/dotfiles help")
    assert_match opt_prefix.to_s, shell_output("#{bin}/dotfiles path")
  end
end
