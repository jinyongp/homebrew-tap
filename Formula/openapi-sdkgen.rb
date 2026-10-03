# releaseway-version: 10.1.1
# releaseway-source-commit: 6c349f9d098e175b242f49d3d28cefe6f2e3f731
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/6c349f9d098e175b242f49d3d28cefe6f2e3f731.tar.gz"
  version "10.1.1"
  sha256 "0e6bf07af2c3fb80968a62d8f8ec692d923623f8d2a8696d9e2253bf7e6fb6e3"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    system "go", "build", "-trimpath", "-ldflags=-s -w -X main.version=#{version}", "-o", bin/"openapi-sdkgen", "./cmd/openapi-sdkgen"
  end

  test do
    assert_equal "openapi-sdkgen #{version}\n", shell_output("#{bin}/openapi-sdkgen --version")
    system bin/"openapi-sdkgen", "--help"
  end
end
