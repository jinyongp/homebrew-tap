class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.3.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.3.0/gate-darwin-arm64", using: :nounzip
      sha256 "a6a64063c92cbf2cb92008b36291496c7acee9d71b29f7ff2b0565bf83dc0652"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.3.0/gate-darwin-amd64", using: :nounzip
      sha256 "8a72d92671a4448fba094b9ce01e70b1db919e368a1a1da2b5d7d8cc94fd9cd1"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.3.0/gate-linux-arm64", using: :nounzip
      sha256 "1c21e5ede6fe897f46ef1d2178b67d6b77eb969fe5027a73d0eec26541424542"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.3.0/gate-linux-amd64", using: :nounzip
      sha256 "3b46a735e1d4b78f5e2606a20b95385ea215a799e3539a2e74ac6f0972f867cd"
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
