class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  url "https://github.com/jinyongp/gate/archive/06c0000832616a75850f2fe245c0160264c773f2.tar.gz"
  version "1.2.3"
  sha256 "df437fed7d98c63875de78cc5ee4a5d4f60a8a7f3a5a2b6e7b963dec579c4dd1"
  license "MIT"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=v#{version}", output: bin/"gate"), "./cmd/gate"
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
