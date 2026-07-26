class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.11.1"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.11.1/gate-darwin-arm64", using: :nounzip
      sha256 "2408049b7e3385560abe4b435e709e340ea4dcca030667ec28d6d935eb104fb4"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.11.1/gate-darwin-amd64", using: :nounzip
      sha256 "ade79b21f7dbdfe6cf313d916aac9d6ab0a8ef5f30c0114d64227ba5bfec9280"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.11.1/gate-linux-arm64", using: :nounzip
      sha256 "5a13e82376d4ad0337042794f8a53479e13d96df521f9e7abf267053e2b60578"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.11.1/gate-linux-amd64", using: :nounzip
      sha256 "314d0ba5029c2c908eb2561b66d5273f56ae7b6c1cf5d552eec2382af1e006f2"
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
