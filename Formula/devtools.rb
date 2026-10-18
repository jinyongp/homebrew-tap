# releaseway-version: 0.27.0
# releaseway-source-commit: 89100eb98888895a450b2ebd403e4e1c9b5f52d2
class Devtools < Formula
  desc "Agent-first developer environment and task management"
  homepage "https://github.com/jinyongp/devtools"
  url "https://github.com/jinyongp/devtools/archive/89100eb98888895a450b2ebd403e4e1c9b5f52d2.tar.gz"
  version "0.27.0"
  sha256 "ace339fd6ddc0124acfe9abd4d428f65bd821c4a130cc4e8de08f63b191cd017"
  license "MIT"

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    ENV["GOTOOLCHAIN"] = "go#{File.read("go.mod").match(/^go (\S+)$/)[1]}"
    ldflags = "-s -w -X main.version=#{version} -X github.com/jinyongp/devtools/internal/cli.updateManager=homebrew"
    system "go", "build", *std_go_args(ldflags: ldflags), "./cmd/devtools"
    generate_completions_from_executable(bin/"devtools", "completion")

    unless (bin/"devtools").file?
      odie "command_aliases.dvt: target devtools must be an installed executable"
    end
    unless (bin/"devtools").executable?
      odie "command_aliases.dvt: target devtools must be an installed executable"
    end
    if (bin/"dvt").exist? || (bin/"dvt").symlink?
      odie "command_aliases.dvt: destination already exists"
    end
    bin.install_symlink (bin/"devtools") => "dvt"
  end

  test do
    assert_path_exists bash_completion/"devtools"
    assert_path_exists zsh_completion/"_devtools"
    assert_path_exists fish_completion/"devtools.fish"
    assert_match version.to_s, shell_output("#{bin}/devtools version")
    assert_match version.to_s, shell_output("#{bin}/dvt version")
    system bin/"devtools", "init", "--profile", "homebrew-test"
    system bin/"devtools", "var", "set", "LEVEL", "--value", "debug"
    assert_match "debug", shell_output("#{bin}/devtools var get LEVEL")
    assert_match "package_managed", shell_output("#{bin}/devtools update 2>&1", 3)
  end
end
