class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.10.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.10.0/gate-darwin-arm64", using: :nounzip
      sha256 "917cf942a5a9df1d556d59f132f806c3131e7581dda8170aa48e641704ab18c0"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.10.0/gate-darwin-amd64", using: :nounzip
      sha256 "be29e79eea78eb1fc50cf7e24d70498b602cb34c0ff7f7b0a952e2de1af0d86c"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.10.0/gate-linux-arm64", using: :nounzip
      sha256 "e5ca120e5f64d9777c6f2073d5de6dcbe5390a9e95455d21bfcbdd456ba13b42"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.10.0/gate-linux-amd64", using: :nounzip
      sha256 "f95ae30a2a66e5bd90f7d1e83ab3d6cae27453394a9969f7fccfabe9e10f991f"
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
