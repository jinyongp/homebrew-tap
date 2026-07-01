class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.6.1"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.6.1/gate-darwin-arm64", using: :nounzip
      sha256 "34a7b8f4b5876893c81cba0ba69d466d69bb5813cce397dcc751357841cf45e0"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.6.1/gate-darwin-amd64", using: :nounzip
      sha256 "71b072c848a714a4d1f92b18c2cf6b0055ddd1fd3f015cab0b55104009e12e9b"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.6.1/gate-linux-arm64", using: :nounzip
      sha256 "2fa010de227901ba69c80476259dd80919bf24ee1d1edc4a8937fe47b1cf9b5e"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.6.1/gate-linux-amd64", using: :nounzip
      sha256 "5f5bf45968795a82da5e55641ceff4406c6e398ef5ece29134fa4b543332d8e6"
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
