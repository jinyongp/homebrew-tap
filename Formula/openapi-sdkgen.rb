# releaseway-version: 1.4.0
# releaseway-source-commit: 6231d70af9d162ac7fd50099c028ed9860f36c0c
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/6231d70af9d162ac7fd50099c028ed9860f36c0c.tar.gz"
  version "1.4.0"
  sha256 "890ecfcafe6fa30f38cd6c50410560cb7048771fee019900fdbc248fa23287cb"
  license "Apache-2.0"
  version_scheme 1

  depends_on "go" => :build

  def install
    system "go", "build", "-trimpath", "-ldflags=-s -w -X main.version=#{version}", "-o", bin/"openapi-sdkgen", "./cmd/openapi-sdkgen"
  end

  test do
    assert_equal "openapi-sdkgen #{version}\n", shell_output("#{bin}/openapi-sdkgen --version")
    system bin/"openapi-sdkgen", "--help"
  end
end
