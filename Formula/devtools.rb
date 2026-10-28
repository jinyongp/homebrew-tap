# releaseway-version: 0.37.0
# releaseway-source-commit: f8c22ac3674a14c8d57ed919e866fc104d6d7b5f
class Devtools < Formula
  desc "Agent-first developer environment and task management"
  homepage "https://github.com/jinyongp/devtools"
  url "https://github.com/jinyongp/devtools/archive/f8c22ac3674a14c8d57ed919e866fc104d6d7b5f.tar.gz"
  version "0.37.0"
  sha256 "9ff90cb6bd4d72706cb4162f490e45ce9632ce9458937fd0f48cfe6a48c6e6c0"
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
