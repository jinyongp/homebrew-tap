# releaseway-version: 0.28.1
# releaseway-source-commit: 832ab00ff14f20f490a8b7ec0037b7d4bb207841
class Devtools < Formula
  desc "Agent-first developer environment and task management"
  homepage "https://github.com/jinyongp/devtools"
  url "https://github.com/jinyongp/devtools/archive/832ab00ff14f20f490a8b7ec0037b7d4bb207841.tar.gz"
  version "0.28.1"
  sha256 "752653d3de4b9d11c6925501be37965cf6654f32e773450dc8a2dffabc78b841"
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
