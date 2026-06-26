class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.5.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.5.0/gate-darwin-arm64", using: :nounzip
      sha256 "50524d0d4779fc52ef4e441a67dc7f345be1cc242d446fa5f00b82508132f2c9"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.5.0/gate-darwin-amd64", using: :nounzip
      sha256 "32798ef91635eae0d82b3ea04d38785b60eddfab5baf11608894ec22e6196d71"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.5.0/gate-linux-arm64", using: :nounzip
      sha256 "0a89f44ddc7311af0366e6b42d08f7f6a0482c692e50e6ad2ccda3f3aa0ba380"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.5.0/gate-linux-amd64", using: :nounzip
      sha256 "ce600a0bea6c0f8aabb940b3b4ce3fd0f8fa46dc2ccb58f035de2a70a65d0357"
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
