class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.11.2"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.11.2/gate-darwin-arm64", using: :nounzip
      sha256 "0aca661f26a84f86cc22c16eca34181c234a2296f5c0ef2bce59d160be31fb7c"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.11.2/gate-darwin-amd64", using: :nounzip
      sha256 "c0a04c54e7aa2f50452d4d3075d1fdd5d33f7c01d6e978df541ba3d02d711bce"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.11.2/gate-linux-arm64", using: :nounzip
      sha256 "8c94b64f3943b3c5bb74cf89eb71b1740f795a8a519d3a30c0d95ec75fa3f72d"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.11.2/gate-linux-amd64", using: :nounzip
      sha256 "c03bc9e55f238910e377d357b08856134db9ba2838512994702408b1d275547e"
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
