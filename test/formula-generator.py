"""Exercise GitHub Release formula generation without external downloads."""

from hashlib import sha256
from pathlib import Path
import os
import subprocess
import tempfile


root = Path(__file__).resolve().parents[1]
generator = root / "actions/publish/formula/generate.sh"
platform_assets = {
    "macos-arm64": "example_1.2.3_darwin_arm64.tar.gz",
    "macos-x86_64": "example_1.2.3_darwin_amd64.tar.gz",
    "linux-arm64": "example_1.2.3_linux_arm64.tar.gz",
    "linux-x86_64": "example_1.2.3_linux_amd64.tar.gz",
}


def git(path, *args):
    result = subprocess.run(
        ["git", "-C", str(path), *args],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr


def spec(distribution):
    lines = [
        "desc: Release fixture",
        "license: MIT",
        *distribution,
        "install: |",
        '  bin.install "example"',
        "test: |",
        '  system "#{bin}/example", "--version"',
    ]
    return "\n".join(lines) + "\n"


with tempfile.TemporaryDirectory() as directory:
    workspace = Path(directory)
    source = workspace / "source"
    tap = workspace / "tap"
    assets = workspace / "assets"
    fake_bin = workspace / "bin"
    for path in [source, tap, assets, fake_bin]:
        path.mkdir()

    git(source, "init", "--initial-branch=main")
    git(source, "config", "user.name", "test")
    git(source, "config", "user.email", "test@example.invalid")
    git(source, "config", "commit.gpgsign", "false")
    git(source, "config", "core.hooksPath", "/dev/null")
    spec_path = source / ".github/homebrew/formula.yml"
    spec_path.parent.mkdir(parents=True)
    spec_path.write_text("desc: placeholder\nlicense: MIT\ninstall: x\ntest: x\n")
    git(source, "add", ".")
    git(source, "commit", "-m", "fixture")
    resolved_ref = subprocess.run(
        ["git", "-C", str(source), "rev-parse", "HEAD"],
        text=True,
        capture_output=True,
        check=True,
    ).stdout.strip()

    for index, asset in enumerate(platform_assets.values()):
        (assets / asset).write_bytes(f"asset-{index}\n".encode())
    (assets / f"{resolved_ref}.tar.gz").write_bytes(b"source-archive\n")

    curl = fake_bin / "curl"
    curl.write_text(
        """#!/bin/sh
set -eu
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) output="$2"; shift 2 ;;
    -*) shift ;;
    *) url="$1"; shift ;;
  esac
done
cp "$FAKE_RELEASE_DIR/${url##*/}" "$output"
"""
    )
    curl.chmod(0o755)

    base_env = dict(
        os.environ,
        TAP_PATH=str(tap),
        SOURCE_PATH=str(source),
        FORMULA="example",
        REPOSITORY="owner/example",
        REF="release-commit",
        VERSION="v1.2.3",
        SPEC_PATH=".github/homebrew/formula.yml",
        FAKE_RELEASE_DIR=str(assets),
        PATH=f"{fake_bin}:{os.environ['PATH']}",
    )

    def generate(distribution, expected_error=None):
        spec_path.write_text(spec(distribution))
        output = workspace / "github-output"
        output.write_text("")
        result = subprocess.run(
            ["bash", str(generator)],
            env=dict(base_env, GITHUB_OUTPUT=str(output)),
            text=True,
            capture_output=True,
            check=False,
        )
        if expected_error:
            assert result.returncode != 0, "invalid release distribution should fail"
            assert expected_error in result.stderr, result.stderr
            return None
        assert result.returncode == 0, result.stderr
        return output.read_text()

    output = generate([])
    formula = (tap / "Formula/example.rb").read_text()
    assert "distribution=source" in output
    assert 'runner-matrix=["macos-latest"]' in output
    assert "  depends_on :macos\n" not in formula
    assert "  depends_on :linux\n" not in formula

    output = generate([
        "distribution:",
        "  type: github-release",
        '  tag: "v{version}"',
        "  assets:",
        *[f"    {platform}: {asset.replace('1.2.3', '{version}')}" for platform, asset in platform_assets.items()],
    ])
    formula = (tap / "Formula/example.rb").read_text()
    assert 'version "1.2.3"' in formula
    assert "  depends_on :macos\n" not in formula
    assert "  depends_on :linux\n" not in formula
    assert formula.count("on_macos do") == 1
    assert formula.count("on_linux do") == 1
    def source_lines(platform):
        asset = platform_assets[platform]
        url = f"https://github.com/owner/example/releases/download/v1.2.3/{asset}"
        checksum = sha256((assets / asset).read_bytes()).hexdigest()
        return f'url "{url}"', f'sha256 "{checksum}"'

    for os_name, arm_platform, intel_platform in [
        ("macos", "macos-arm64", "macos-x86_64"),
        ("linux", "linux-arm64", "linux-x86_64"),
    ]:
        arm_url, arm_checksum = source_lines(arm_platform)
        intel_url, intel_checksum = source_lines(intel_platform)
        expected_block = f"""  on_{os_name} do
    if Hardware::CPU.arm?
      {arm_url}
      {arm_checksum}
    else
      {intel_url}
      {intel_checksum}
    end
  end
"""
        assert expected_block in formula
    assert "distribution=github-release" in output
    assert "release-tag=v1.2.3" in output
    assert 'runner-matrix=["macos-latest","ubuntu-latest"]' in output
    assert "archive-url=\n" in output
    assert "sha256=\n" in output

    macos_assets = {key: value for key, value in platform_assets.items() if key.startswith("macos-")}
    output = generate([
        "distribution:",
        "  type: github-release",
        '  tag: "v{version}"',
        "  assets:",
        *[f"    {platform}: {asset}" for platform, asset in macos_assets.items()],
    ])
    formula = (tap / "Formula/example.rb").read_text()
    assert "  depends_on :macos\n" in formula
    assert "  on_macos do\n" in formula
    assert "  on_linux do\n" not in formula
    assert 'runner-matrix=["macos-latest"]' in output

    linux_assets = {key: value for key, value in platform_assets.items() if key.startswith("linux-")}
    output = generate([
        "distribution:",
        "  type: github-release",
        '  tag: "v{version}"',
        "  assets:",
        *[f"    {platform}: {asset}" for platform, asset in linux_assets.items()],
    ])
    formula = (tap / "Formula/example.rb").read_text()
    assert "  depends_on :linux\n" in formula
    assert "  on_macos do\n" not in formula
    assert "  on_linux do\n" in formula
    assert 'runner-matrix=["ubuntu-latest"]' in output

    generate([
        "distribution:",
        "  type: github-release",
        '  tag: "v{version}"',
        "  assets:",
        "    macos-arm64: example_{version}_darwin_arm64.tar.gz",
    ], "distribution.assets is missing macos platforms: macos-x86_64")

    generate([
        "distribution:",
        "  type: github-release",
        '  tag: "v{version}"',
        "  assets: {}",
    ], "distribution.assets must declare at least one supported operating system")

    generate([
        "distribution:",
        "  type: github-release",
        '  tag: "v{version}"',
        "  assets:",
        *[f"    {platform}: {asset}" for platform, asset in macos_assets.items()],
        "    windows-x86_64: example_1.2.3_windows_amd64.zip",
    ], "distribution.assets has unsupported platforms: windows-x86_64")

    generate([
        "distribution:",
        "  type: github-release",
        '  tag: "v{channel}"',
        "  assets:",
        *[f"    {platform}: {asset}" for platform, asset in platform_assets.items()],
    ], "distribution.tag contains an unsupported template placeholder")

    generate([
        "distribution:",
        "  type: github-release",
        '  tag: "v{version}"',
        "  assets:",
        *[
            f"    {platform}: {'../escape.tar.gz' if platform == 'linux-arm64' else asset}"
            for platform, asset in platform_assets.items()
        ],
    ], "distribution.assets.linux-arm64 may contain only")

print("GitHub Release formula generation passed")
