# releaseway-version: 11.0.1
# releaseway-source-commit: 5369b37b8733a6a129e1ef807c2e6c1801ca60f6
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/5369b37b8733a6a129e1ef807c2e6c1801ca60f6.tar.gz"
  version "11.0.1"
  sha256 "d2103bdc1873b628857b2eef25c21722d76b796a5a8bdeec3cad3fb25f9ccec8"
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
