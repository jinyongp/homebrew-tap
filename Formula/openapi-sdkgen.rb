# releaseway-version: 1.4.1
# releaseway-source-commit: 7d8f1518a4d425801f80237b0d2a5b60ce34a4d4
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/7d8f1518a4d425801f80237b0d2a5b60ce34a4d4.tar.gz"
  version "1.4.1"
  sha256 "62c302b9834aa963c72e95e7dc7d0b5ebc199f1fc7d5bf04bc772cecc40e7abf"
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
