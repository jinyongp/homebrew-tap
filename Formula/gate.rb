class Gate < Formula
  desc "Local-dev global HTTPS reverse proxy and port registry"
  homepage "https://github.com/jinyongp/gate"
  url "https://github.com/jinyongp/gate/archive/84e9d4df9861eaeb26d6b3b75c18a7a64ed3c36e.tar.gz"
  version "1.1.3"
  sha256 "753dfe945b4301f7921752924fa23dadde39b50d5f776f39e75cba9c559f660e"
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
