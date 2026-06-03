class Dotfiles < Formula
  desc "Personal dotfiles and installer"
  homepage "https://github.com/jinyongp/dotfiles"
  url "https://github.com/jinyongp/dotfiles/archive/54f43a74d65626bcd38808ecae95a43c9b154b1a.tar.gz"
  version "54f43a74d656"
  sha256 "0de8243387ecb15a3f4dc1d135592a2cd17eef6fe9f5c2f796a705c0ade960c2"
  license :cannot_represent

  def install
    prefix.install Dir["*"]
    prefix.install Dir[".[!.]*"].reject { |path| File.basename(path) == ".git" }
    bin.write_exec_script opt_prefix/"cmd/dotfiles"
  end

  def caveats
    <<~EOS
      To remove this Homebrew-managed install, run:
        dotfiles uninstall -y

      Use this instead of `brew uninstall dotfiles` so dotfiles-managed shell,
      editor, Git, and agent links are cleaned up before the formula is removed.
    EOS
  end

  test do
    assert_match "COMMANDS", shell_output("#{bin}/dotfiles help")
    assert_match opt_prefix.to_s, shell_output("#{bin}/dotfiles path")
  end
end
