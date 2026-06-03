class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  url "https://github.com/jinyongp/gate/archive/fdee99fcdebceb961e3033eec174afa6aaa673c3.tar.gz"
  version "1.2.2"
  sha256 "18600c6c3e64fc68c86de73b5b8c8746c81bf49b343a317527407aa84e2a19f4"
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
