class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.8.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.8.0/gate-darwin-arm64", using: :nounzip
      sha256 "1c6ac564ec5da529fac7bb349bf95a5512de92ec0cfb29ea41a8adb7ac05d3e8"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.8.0/gate-darwin-amd64", using: :nounzip
      sha256 "75469ac2062091b72a9e3f67d3fe50d33c9e571f12656512968aec746f25dd54"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.8.0/gate-linux-arm64", using: :nounzip
      sha256 "6beeb40bdc3e171dd8e1426a9c0a81c30ab913b682e0e6c893b21bf44b0cb035"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.8.0/gate-linux-amd64", using: :nounzip
      sha256 "d27275c9ad65b31724b21c536899e235ef36797a55870b161e07559cc0334687"
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
