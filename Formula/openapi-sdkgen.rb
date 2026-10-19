# releaseway-version: 1.3.0
# releaseway-source-commit: 623dffd47029a8856d7b1cf4aade0c8dcdc77aac
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/623dffd47029a8856d7b1cf4aade0c8dcdc77aac.tar.gz"
  version "1.3.0"
  sha256 "79b7265329ae0c622b588b70ac5db55486eb106f9608eb7d4dffb1a515e12854"
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
