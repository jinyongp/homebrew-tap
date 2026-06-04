class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  version "2.0.2"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.0.2/gate-darwin-arm64", using: :nounzip
      sha256 "f880e728bf3b2c32cb898419b7ff0b7c272befb6f67528dd84975381fa3ec4be"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.0.2/gate-darwin-amd64", using: :nounzip
      sha256 "bd75f2ac9472d794eb29a6635ee53ac3487a3f9b21dcc96102f069da269721dc"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/jinyongp/gate/releases/download/v2.0.2/gate-linux-arm64", using: :nounzip
      sha256 "17a81bb6a2df69468f940d309f0c9d6003681505eb3e591bc84dd968ac6913a8"
    else
      url "https://github.com/jinyongp/gate/releases/download/v2.0.2/gate-linux-amd64", using: :nounzip
      sha256 "364cb33322c85045fc08b3aebe7d7e4bd6ce9680fd31ec178b6a3dc75abbe9f5"
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
