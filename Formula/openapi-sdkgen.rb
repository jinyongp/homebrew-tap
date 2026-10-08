# releaseway-version: 1.2.0
# releaseway-source-commit: fe010a8dea006a35f9d03cfd33b8749d718e0fc7
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/fe010a8dea006a35f9d03cfd33b8749d718e0fc7.tar.gz"
  version "1.2.0"
  sha256 "9a0ee3edbc78d2e4e6f9ec282794ce6b764ea4e0be13ba8966670b4c6e727535"
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
