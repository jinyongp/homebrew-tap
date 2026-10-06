# releaseway-version: 11.0.2
# releaseway-source-commit: eafcd9c49ac836661fea51e1fe3ad09094c9ba77
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/eafcd9c49ac836661fea51e1fe3ad09094c9ba77.tar.gz"
  version "11.0.2"
  sha256 "7c22b41b8312d15542d848c67721f40150418484740e084b3f8dcedb6fd542b5"
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
