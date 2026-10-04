# releaseway-version: 11.0.0
# releaseway-source-commit: 09be17f76a36327acebadc95bebe5cf41d808de3
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/09be17f76a36327acebadc95bebe5cf41d808de3.tar.gz"
  version "11.0.0"
  sha256 "69bf9ecd234af81b35b448d3849619e66e002526d33427c068df081462b59099"
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
