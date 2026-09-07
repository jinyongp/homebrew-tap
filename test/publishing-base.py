"""Pinned automation must update current Formula history across releases."""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
workflow = (root / '.github/workflows/publish-formula.yml').read_text()
assert workflow.count('ref: main') == 3, 'All credential modes must use current tap main'
assert workflow.count('ref: ${{ job.workflow_sha }}') == 1
assert 'uses: ./tap-tools/actions/publish/formula' in workflow
assert 'bash tap-tools/.github/workflows/scripts/resolve-source-inputs.sh' in workflow
for name in ['commit-formula', 'push-formula']:
    assert f'bash ../tap-tools/.github/workflows/scripts/{name}.sh' in workflow

with tempfile.TemporaryDirectory() as directory:
    path = Path(directory)
    env = dict(os.environ, GIT_CONFIG_GLOBAL='/dev/null', GIT_CONFIG_NOSYSTEM='1')
    def git(cwd, *args, check=True):
        return subprocess.run(['git', '-C', str(cwd), *args], env=env,
                              text=True, capture_output=True, check=check)
    remote = path / 'remote'; remote.mkdir()
    git(remote, 'init', '--bare', '--initial-branch=main')
    work = path / 'work'
    git(path, 'clone', str(remote), str(work))
    git(work, 'config', 'user.name', 'test')
    git(work, 'config', 'user.email', 'test@example.invalid')
    git(work, 'commit', '--allow-empty', '-m', 'pinned automation')
    pinned = git(work, 'rev-parse', 'HEAD').stdout.strip()
    formula = work / 'Formula/example.rb'; formula.parent.mkdir()
    formula.write_text('version "0.1.0"\n')
    git(work, 'add', '.'); git(work, 'commit', '-m', 'first formula')
    git(work, 'push', 'origin', 'main')
    git(work, 'checkout', '--detach', pinned)
    formula.parent.mkdir(exist_ok=True); formula.write_text('version "0.2.0"\n')
    git(work, 'add', '.'); git(work, 'commit', '-m', 'stale add')
    assert git(work, 'rebase', 'origin/main', check=False).returncode != 0
    git(work, 'rebase', '--abort'); git(work, 'checkout', 'main')
    for version in ['0.2.0', '0.3.0']:
        formula.write_text(f'version "{version}"\n')
        output = path / 'outputs'; output.write_text('')
        settings = dict(env, GITHUB_OUTPUT=str(output), FORMULA_PATH='Formula/example.rb',
                        FORMULA='example', VERSION=version)
        for script in ['commit-formula', 'push-formula']:
            subprocess.run(['bash', str(root / f'.github/workflows/scripts/{script}.sh')],
                           cwd=work, env=settings, capture_output=True, check=True)
        assert git(remote, 'show', 'main:Formula/example.rb').stdout == formula.read_text()
print('Pinned-base conflict reproduced; current-main successive publishing passed')
