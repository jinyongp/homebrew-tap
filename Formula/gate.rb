class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.7.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.7.0/gate-darwin-arm64", using: :nounzip
      sha256 "96f331e17db71487baa8f073a87da915364a47c6472c9d6aa615483cfbfefa58"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.7.0/gate-darwin-amd64", using: :nounzip
      sha256 "361d1bd29b287a83422659f6692dd88ed6397d35acafa8862ddb292229d28d61"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.7.0/gate-linux-arm64", using: :nounzip
      sha256 "8cd4bcd2bbb8d1e4c3129552c0b3fb250129e523140de65de5e4d007cc13fc89"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.7.0/gate-linux-amd64", using: :nounzip
      sha256 "714be9227cbd6af0ec5b80353ecb3121ec80a1f24c27093d74a80c0d8941c27e"
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
