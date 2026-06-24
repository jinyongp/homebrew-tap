class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.4.3"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.4.3/gate-darwin-arm64", using: :nounzip
      sha256 "993255d5108472b07754496f8a77cffae1d3abc31f1f7555a4adf7b577d4be2b"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.4.3/gate-darwin-amd64", using: :nounzip
      sha256 "f7a9a77e4f7527e84d97a34e2edead6c6733fddc017abd1d356e3cf6a31f9a85"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.4.3/gate-linux-arm64", using: :nounzip
      sha256 "a1d705e6766858e3a5f507a5b894d8c8757d63b15ebe829801fca66c90e53932"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.4.3/gate-linux-amd64", using: :nounzip
      sha256 "79348744ff64d3e3a06759e45f3cdcfc19e3160d81ff8bb2bfdd57610ea62d2e"
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
