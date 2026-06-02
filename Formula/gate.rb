class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  url "https://github.com/jinyongp/gate/archive/9dae4291f3d8bbc94e913417a82e28c8b4dd37a8.tar.gz"
  version "1.0.0-pre"
  sha256 "6da0832abc46d3b1be09e4a15a73e215593c4dd30ca6ce725d37f8257f7da542"
  license :cannot_represent

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
