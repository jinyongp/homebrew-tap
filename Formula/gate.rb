class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/jinyongp/gate/releases/download/v3.0.0/gate-darwin-arm64"
      sha256 "e4c5c9adf940845528738014382ff1a0c55e7551774c885f2f30a412d0384612"
    end
    on_intel do
      url "https://github.com/jinyongp/gate/releases/download/v3.0.0/gate-darwin-amd64"
      sha256 "efe5f205171739196c52f775b4e6f16fdb348032e6ede445faf4e5d077287f83"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/jinyongp/gate/releases/download/v3.0.0/gate-linux-arm64"
      sha256 "82f54c13ddfe60c8403e4f2b1600d8a5636558a1f15d4314890a3c9a95549d58"
    end
    on_intel do
      url "https://github.com/jinyongp/gate/releases/download/v3.0.0/gate-linux-amd64"
      sha256 "6f8f390d4f5dc9f5b70299fac4144596b91d4d369facf8a1dd42e49a4c8113dc"
    end
  end

  def install
    asset = Dir["gate-*"].first
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
