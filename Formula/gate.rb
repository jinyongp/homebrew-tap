class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.10.1"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.10.1/gate-darwin-arm64", using: :nounzip
      sha256 "c03cf803ea6337c1964858eeadb4ec34b8ca1aaf2ca96916125c185ad844228c"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.10.1/gate-darwin-amd64", using: :nounzip
      sha256 "6d545ed05fa7792cb58d18340f908795ed26360b1b5f9e5cb087a9e40a2439ee"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.10.1/gate-linux-arm64", using: :nounzip
      sha256 "8006bbdb95efa1a3fd289bc7d1d8b4d8c1b0a6478a007a4ba4a0c75e1fa8cadc"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.10.1/gate-linux-amd64", using: :nounzip
      sha256 "184f8a9412f3180c726eee79f9b76b510d191da2f92c82fa16c63010df3286b8"
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
