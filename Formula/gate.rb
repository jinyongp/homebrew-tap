class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.0.3"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.0.3/gate-darwin-arm64", using: :nounzip
      sha256 "f49c45f4579dc52d1281bb645639b6904f95e53f0df5724a2b88a9ffc332b1bd"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.0.3/gate-darwin-amd64", using: :nounzip
      sha256 "8c23195b8ba99a68edc9791c11c5efcca08a2c5a78d3cb7ab9e6e3530b9eabc2"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.0.3/gate-linux-arm64", using: :nounzip
      sha256 "d39f13d05c2986de4739eab82188d3bee24d766da829d5b4348e2bb5c205fcb7"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.0.3/gate-linux-amd64", using: :nounzip
      sha256 "02b80fec238bcc5f0dbeb56af665f7f0513d66df5775b87927a4459336747be1"
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
