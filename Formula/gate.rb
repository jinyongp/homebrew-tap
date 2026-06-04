class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.0.1"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.0.1/gate-darwin-arm64", using: :nounzip
      sha256 "af2d8f3fbeac742e04975e60c6c58f0b068708047a63938ce03413653b94922a"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.0.1/gate-darwin-amd64", using: :nounzip
      sha256 "e3a78a5f11d09622cbbc0b1474f738b988e7a36728c69acd815fafe3bd9c8dd1"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.0.1/gate-linux-arm64", using: :nounzip
      sha256 "6eda4e7d9412116c90f6729f1231a6b5a9c62f04c60f08eb4af3627d5e641582"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.0.1/gate-linux-amd64", using: :nounzip
      sha256 "2b3fcfba4891a798f20ecad4b5ad0da6e6d06a83ed84bcc65022db23e2ebd3a9"
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
