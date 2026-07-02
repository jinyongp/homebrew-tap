class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.7.1"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.7.1/gate-darwin-arm64", using: :nounzip
      sha256 "a26d4a53ca083f07f102c3d6d604e89a030517145913f6b89702bca98e7606b5"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.7.1/gate-darwin-amd64", using: :nounzip
      sha256 "098abc6a5df5ab32dcaa160d7c1c6b0a24eeb29c13bcd306ca77e522ff3080e3"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.7.1/gate-linux-arm64", using: :nounzip
      sha256 "c46d5ded56d821ed41e0125a042e5ff6f4788414c69e758f430e15e16b7226d6"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.7.1/gate-linux-amd64", using: :nounzip
      sha256 "95e234bd8d0bb7f7f6631dc644e78f5c50b5add91f3422fcdc762373c5267cec"
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
