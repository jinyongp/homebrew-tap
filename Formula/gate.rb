class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.1.0/gate-darwin-arm64", using: :nounzip
      sha256 "a1e377f4f29a798f7f437a7d3e6c1bd2ad3941eb1cb41ca68514b417e7d3607f"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.1.0/gate-darwin-amd64", using: :nounzip
      sha256 "73044ecb62d33e966f66b01cb3c3235fc76a2606f876a06d70701da2a0f627f7"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.1.0/gate-linux-arm64", using: :nounzip
      sha256 "428cdae82bb22f3fccd33f16bef17a05c8f2f9742c5a85171655694343807e23"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.1.0/gate-linux-amd64", using: :nounzip
      sha256 "3a1db957cfac82e40bd1dd19b772c44cd5211ce07308e7f7dad6ac7fc6ed0dbe"
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
