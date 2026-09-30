class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/2747cb98df8d269e27d5c4cde988098d43600226.tar.gz"
  version "8.4.0"
  sha256 "c281bef40da068533eee8e0ee39298d2da4dfa919cb5bf1dc65813e7884ae351"
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
