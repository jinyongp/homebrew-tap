class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.11.4"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.11.4/gate-darwin-arm64", using: :nounzip
      sha256 "7e4fa15a30d32a7b76b61a1d4b884cad732746ee2f33cef16d5c16eb5dea5b27"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.11.4/gate-darwin-amd64", using: :nounzip
      sha256 "fa6cd167e94b683e21e3bff96d38f226b077dd596cc2482e2855b7f9e0fb1f6b"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.11.4/gate-linux-arm64", using: :nounzip
      sha256 "8977792d9d006392fc6c34a7e6dd990fed0ff2cf4544c6a2f5948380c20e0dc8"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.11.4/gate-linux-amd64", using: :nounzip
      sha256 "9d0ab73d68662aa6e6e0f681875256d811ef62112424a294a38a22d2ff717916"
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
