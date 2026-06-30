class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.6.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.6.0/gate-darwin-arm64", using: :nounzip
      sha256 "11e013ddd2b3e49c05c05cbb14f91ee28dc7a3f665528b3eb39e880bffc3f93b"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.6.0/gate-darwin-amd64", using: :nounzip
      sha256 "0f679f3b3773afcbc81cb5aef6e1c069ba28c1eb373ef743675a2286dcb5c6de"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.6.0/gate-linux-arm64", using: :nounzip
      sha256 "4e4ba4e0554dc86ed540ecc8c66e5b807576400164f6c008fa51815910ba57fd"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.6.0/gate-linux-amd64", using: :nounzip
      sha256 "aeab768d29ae9152f0727acbc9c0779cd46ece37039dd79686d4d4924543a76b"
    end
  end

  def install
    asset = if OS.mac?
      Hardware::CPU.arm? ? "gate-darwin-arm64" : "gate-darwin-amd64"
    elsif OS.linux?
      Hardware::CPU.arm? ? "gate-linux-arm64" : "gate-linux-amd64"
    else
      odie "unsupported platform"
    end

    chmod 0755, asset
    bin.install asset => "gate"
    generate_completions_from_executable(bin/"gate", "completion")
  end

  def caveats
    <<~EOS
      For full cleanup, run:
        gate uninstall

      `brew uninstall gate` removes only the Homebrew package. It does not remove
      gate's local state, trusted root CA, managed hosts block, or shell PATH block.
    EOS
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/gate --version")
  end
end
