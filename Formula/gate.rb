class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  url "https://github.com/jinyongp/gate/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "07a7e41114ab646be2efd40a8437f0709bf11197f2dc6cca7ba02374f39636a6"
  license "MIT"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(
      ldflags: "-s -w -X main.version=v#{version}",
      output:  bin/"gate",
    ), "./cmd/gate"
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/gate --version")
  end
end
