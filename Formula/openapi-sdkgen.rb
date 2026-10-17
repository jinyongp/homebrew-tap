# releaseway-version: 1.2.1
# releaseway-source-commit: 291ba2414b38ec625ef1cacedd99e329f1fbe60f
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/291ba2414b38ec625ef1cacedd99e329f1fbe60f.tar.gz"
  version "1.2.1"
  sha256 "e5c074158547eef9e525ac73a2303cfbbf157da0672e8db6f1efe0c4b6740e88"
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
