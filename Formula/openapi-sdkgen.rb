# releaseway-version: 1.4.2
# releaseway-source-commit: 5021b594dbb229f170929fb0ed596dab14b134bd
class OpenapiSdkgen < Formula
  desc "Generate application SDK source from OpenAPI documents"
  homepage "https://jinyongp.github.io/openapi-sdkgen/"
  url "https://github.com/jinyongp/openapi-sdkgen/archive/5021b594dbb229f170929fb0ed596dab14b134bd.tar.gz"
  version "1.4.2"
  sha256 "b690363c5881dc09a0b6e109b1c7c05abb7697c4c257247afaf3c28f190422c5"
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
