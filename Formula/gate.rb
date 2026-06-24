class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.4.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.4.0/gate-darwin-arm64", using: :nounzip
      sha256 "eef01af9776cf37eb813a95046a2c9233e5740f0c51d727dca975452e12da1b8"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.4.0/gate-darwin-amd64", using: :nounzip
      sha256 "53353b7c780620116ba10bfbaa117e749409d31d7df968c36e4d0546fdd9821e"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.4.0/gate-linux-arm64", using: :nounzip
      sha256 "5ec61351b4667263e3b5a27ecbaf05d84c4e83c90ac72ffbd5175c9017fb8fcf"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.4.0/gate-linux-amd64", using: :nounzip
      sha256 "28f16b5241040edc02caa7390792e4db8cad8e5b9e7bfc9d484975988bd8598e"
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
