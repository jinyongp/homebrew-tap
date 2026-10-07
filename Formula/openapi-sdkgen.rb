# releaseway-version: 11.0.4
# releaseway-source-commit: 9b6c2dcf816154a0e8bbd648e68837a7b8bccdaa
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/9b6c2dcf816154a0e8bbd648e68837a7b8bccdaa.tar.gz"
  version "11.0.4"
  sha256 "59d0eaafa8b4bc7746d7f1fb326bfc0eafb4eaff7f9dd4bffac7ef1b5a087603"
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
