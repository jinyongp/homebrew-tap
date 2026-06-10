class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.2.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.2.0/gate-darwin-arm64", using: :nounzip
      sha256 "9892a7d03fc8b57c9c8a9bd40457cafcb75e086c8ff9b4eb8cde21487409e463"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.2.0/gate-darwin-amd64", using: :nounzip
      sha256 "b0eb85e3a6a10360ba735316275fdb68c36537d165a31602e79e7e37da79bf4f"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.2.0/gate-linux-arm64", using: :nounzip
      sha256 "e91f4bec18191d8cd0674f45758822911187e91313187b243e239a8920037933"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.2.0/gate-linux-amd64", using: :nounzip
      sha256 "ec76834d7cba99229ecd4705b689f0d9743267f15474a9ef1f51d0683910db0a"
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
