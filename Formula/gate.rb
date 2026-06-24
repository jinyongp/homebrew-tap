class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.4.1"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.4.1/gate-darwin-arm64", using: :nounzip
      sha256 "af6b4d3c68340ef6680062d01694943147272988f1e2a3c5586ec8d7875607ae"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.4.1/gate-darwin-amd64", using: :nounzip
      sha256 "06da766f88cfeda857ac7545ec38bfd36bfc9b0da0b2cec5b982648df3a127e2"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.4.1/gate-linux-arm64", using: :nounzip
      sha256 "d8660737ebe53470257d9be1020bd41629899ba5d33e951b1f35cf15ebef930e"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.4.1/gate-linux-amd64", using: :nounzip
      sha256 "cf6c3b2eb2c8d63f53d620faa1726802ccd928b9597c0e802f9eeb6f8a9dbeb0"
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
