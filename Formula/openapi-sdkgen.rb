class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/57fadacaa4af7517da5ea3639478e1827c4a2954.tar.gz"
  version "8.4.1"
  sha256 "21c3d564b0e3de917c0796c613953c25ee5bb33336d11b32a159085b4d39940d"
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
