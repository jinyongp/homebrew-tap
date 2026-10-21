# releaseway-version: 1.3.1
# releaseway-source-commit: 54723748893e32b8b46e2dec530629eb3fc3a8a3
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/54723748893e32b8b46e2dec530629eb3fc3a8a3.tar.gz"
  version "1.3.1"
  sha256 "b4c09ec75589af3a045e90063b0199a8133cba963d7c2115fb7e1ec462caf1c8"
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
