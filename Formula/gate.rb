class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.1.3"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.1.3/gate-darwin-arm64", using: :nounzip
      sha256 "8f29636660e92ae9f3328c2e0cde056ece6d4041ea7f9f1ae3a294fb79149a67"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.1.3/gate-darwin-amd64", using: :nounzip
      sha256 "34f84c33276e9cc3a7f87ea831cce56d347e902ebabc69280aa0613d83a8d615"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.1.3/gate-linux-arm64", using: :nounzip
      sha256 "749f8000a5870ec9f0438be237f122859b3260c7d4580f5c85a1c838612756ce"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.1.3/gate-linux-amd64", using: :nounzip
      sha256 "5f391326b0acd2edd746108d9245ca3d890723d836a705459fef0947f214af29"
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
