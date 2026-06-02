class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  url "https://github.com/jinyongp/gate/archive/refs/tags/v1.1.1.tar.gz"
  sha256 "bfb1d4fe9faf42b22a95374a7cfb245bd70cfdf82dbffa531650f94f7c0b8954"
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
