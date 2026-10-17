# releaseway-version: 0.25.1
# releaseway-source-commit: 52fc9735e1d23684fa842d51da39b2e03482dc27
class Devtools < Formula
  desc "Agent-first developer environment and task management"
  homepage "https://github.com/jinyongp/devtools"
  url "https://github.com/jinyongp/devtools/archive/52fc9735e1d23684fa842d51da39b2e03482dc27.tar.gz"
  version "0.25.1"
  sha256 "725a493b2234270bdac479931a33d8f6b02b972e2a123a7ab3bcb4d1eda8ee6f"
  license "MIT"

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    ENV["GOTOOLCHAIN"] = "go#{File.read("go.mod").match(/^go (\S+)$/)[1]}"
    ldflags = "-s -w -X main.version=#{version} -X github.com/jinyongp/devtools/internal/cli.updateManager=homebrew"
    system "go", "build", *std_go_args(ldflags: ldflags), "./cmd/devtools"
    generate_completions_from_executable(bin/"devtools", "completion")
  end

  test do
    assert_path_exists bash_completion/"devtools"
    assert_path_exists zsh_completion/"_devtools"
    assert_path_exists fish_completion/"devtools.fish"
    assert_match version.to_s, shell_output("#{bin}/devtools version")
    system bin/"devtools", "init", "--profile", "homebrew-test"
    system bin/"devtools", "var", "set", "LEVEL", "--value", "debug"
    assert_match "debug", shell_output("#{bin}/devtools var get LEVEL")
    assert_match "package_managed", shell_output("#{bin}/devtools update 2>&1", 3)
  end
end
