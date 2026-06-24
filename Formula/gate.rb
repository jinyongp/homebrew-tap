class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.4.2"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.4.2/gate-darwin-arm64", using: :nounzip
      sha256 "99e2af648293dff5c85cd62551aabd1c230205386cf7cd48e22663b88edcb960"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.4.2/gate-darwin-amd64", using: :nounzip
      sha256 "60c7912f1a33f2a5f36c952c83e8567589ad78c96204a8704f8cb352bd04d45d"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.4.2/gate-linux-arm64", using: :nounzip
      sha256 "51f7bf27026e56ad672b37a2b1700241cee81008f30d5aed6701e62282ddc98d"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.4.2/gate-linux-amd64", using: :nounzip
      sha256 "c0619275944facc63dd47cfe2c81bd0c90341ba9ed8c23844f70a753dcdcef40"
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
