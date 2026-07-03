class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.9.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.9.0/gate-darwin-arm64", using: :nounzip
      sha256 "b8b68a7af2fd5c0b502d687b4cd805331de401f3d37313c9dd8809a2d6d45bd6"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.9.0/gate-darwin-amd64", using: :nounzip
      sha256 "293cd6cb05afcf17b2c9abb969ddaef38d77515368168e3257589fa0b2b99960"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.9.0/gate-linux-arm64", using: :nounzip
      sha256 "0697ae88b0f662a5a961838951e3dd4171bd6082aa811ceebea74c06b4082b31"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.9.0/gate-linux-amd64", using: :nounzip
      sha256 "4955abba51478d10f78e17ed63d78b16e7aa9a680c44fb4d213a099c404ea629"
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
