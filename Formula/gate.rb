class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.11.3"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.11.3/gate-darwin-arm64", using: :nounzip
      sha256 "f0a57016d0f3889300e0381e11b1fc872b9286e3d0e38a8d4a8dbd9fa7f32e50"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.11.3/gate-darwin-amd64", using: :nounzip
      sha256 "7dc19a6e15a2433c0594ccb7b465ba4ed567c5fec317c65fab76e6c93e3ba708"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.11.3/gate-linux-arm64", using: :nounzip
      sha256 "f6a96f07e3ca8c1b33bc0c14b67b3b886711c9980e19945967d977b6fa144953"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.11.3/gate-linux-amd64", using: :nounzip
      sha256 "02ef6ff8aba7de865dc98b961cb580916a1800c979a910aac32b335323413026"
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
