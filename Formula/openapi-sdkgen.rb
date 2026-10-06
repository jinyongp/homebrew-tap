# releaseway-version: 11.0.3
# releaseway-source-commit: ad4366eb2fa1946c4bdad84bfadc95dc6ac3f1ad
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/ad4366eb2fa1946c4bdad84bfadc95dc6ac3f1ad.tar.gz"
  version "11.0.3"
  sha256 "ec74f75e048e4ab756f761bc7f1e233ea52d0476ba19bb629bbca71ee1ae2662"
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
