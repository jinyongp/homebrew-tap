"""Pinned automation must update current Formula history across releases."""
from pathlib import Path
import json
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
workflow = (root / '.github/workflows/publish-formula.yml').read_text()
auto_merge = (root / '.github/workflows/auto-merge-homebrew-tap.yml').read_text()
validation = (root / '.github/workflows/scripts/validate-formula.sh').read_text()
assert workflow.count('ref: main') == 4, 'Generation, validation, and publishing must use current tap main'
assert workflow.count('ref: ${{ job.workflow_sha }}') == 3
assert 'uses: ./tap-tools/actions/publish/formula' in workflow
assert 'bash tap-tools/.github/workflows/scripts/resolve-source-inputs.sh' in workflow
assert 'bash tap-tools/.github/workflows/scripts/validate-formula.sh' in workflow
assert 'actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4' in workflow
assert workflow.count('actions/download-artifact@d3f86a106a0bac45b974a628896c90dbdf5c8093 # v4') == 2
assert 'Homebrew/actions/setup-homebrew@082c94ee19e776205cfa8e43802917d1425e2fe7 # main' in workflow
assert 'fromJSON(needs.generate.outputs.runner-matrix)' in workflow
trust_validation_tap = validation.index('brew trust --tap "$validation_path"')
install_validation_tap = validation.index('brew tap "$validation_tap" "$validation_path"')
assert trust_validation_tap < install_validation_tap, 'Validation tap must be trusted before Homebrew verifies it'
for name in ['commit-formula', 'push-formula']:
    assert f'bash ../tap-tools/.github/workflows/scripts/{name}.sh' in workflow

assert "github.event_name == 'pull_request_target'" in auto_merge
assert "github.event.pull_request.user.login == 'dependabot[bot]'" in auto_merge
assert 'dependabot/fetch-metadata@25dd0e34f4fe68f24cc83900b1fe3fe149efef98 # v3' in auto_merge
assert 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1' in auto_merge
assert 'repository: ${{ job.workflow_repository }}' in auto_merge
assert 'ref: ${{ job.workflow_sha }}' in auto_merge
assert 'persist-credentials: false' in auto_merge
assert 'UPDATED_DEPENDENCIES' in auto_merge
assert 'gh pr merge --auto --squash' in auto_merge
assert 'ref: ${{ github.event.pull_request.head.sha }}' not in auto_merge

authorization_script = root / '.github/workflows/scripts/authorize-homebrew-tap-update.py'
sha = 'a' * 40
old_sha = 'b' * 40
publish_dependency = {
    'dependencyName': 'jinyongp/homebrew-tap/.github/workflows/publish-formula.yml',
    'packageEcosystem': 'github_actions',
}
auto_merge_dependency = {
    'dependencyName': 'jinyongp/homebrew-tap/.github/workflows/auto-merge-homebrew-tap.yml',
    'packageEcosystem': 'github_actions',
}
dependabot_commit = {
    'author': {'login': 'dependabot[bot]'},
    'commit': {'verification': {'verified': True}},
}
workflow_contents = {
    'release.yml': f'jobs:\n  publish:\n    uses: {publish_dependency["dependencyName"]}@{sha}\n',
    'auto-merge.yml': f'jobs:\n  authorize:\n    uses: {auto_merge_dependency["dependencyName"]}@{sha}\n',
}
workflow_filenames = {
    publish_dependency['dependencyName']: '.github/workflows/release.yml',
    auto_merge_dependency['dependencyName']: '.github/workflows/auto-merge.yml',
}

def changed_files_for(dependencies):
    return [{
        'filename': workflow_filenames[dependency['dependencyName']],
        'status': 'modified',
        'patch': (
            '@@ -1 +1 @@\n'
            f'-    uses: {dependency["dependencyName"]}@{old_sha}\n'
            f'+    uses: {dependency["dependencyName"]}@{sha}'
        ),
    } for dependency in dependencies]

def base_workflows_for(changed_dependencies):
    changed_names = {dependency['dependencyName'] for dependency in changed_dependencies}
    return {
        name: contents.replace(f'@{sha}', f'@{old_sha}')
        if dependency['dependencyName'] in changed_names else contents
        for (name, contents), dependency in zip(
            workflow_contents.items(), [publish_dependency, auto_merge_dependency]
        )
    }

def authorized(metadata=None, commits=None, files=None, base_workflows=None,
               head_workflows=None,
               expected_commit_count=None, expected_file_count=None,
               latest_sha=sha):
    metadata = [publish_dependency, auto_merge_dependency] if metadata is None else metadata
    commits = [dependabot_commit] if commits is None else commits
    files = changed_files_for([publish_dependency, auto_merge_dependency]) if files is None else files
    base_workflows = (base_workflows_for([publish_dependency, auto_merge_dependency])
                      if base_workflows is None else base_workflows)
    head_workflows = workflow_contents if head_workflows is None else head_workflows
    expected_commit_count = len(commits) if expected_commit_count is None else expected_commit_count
    expected_file_count = len(files) if expected_file_count is None else expected_file_count
    with tempfile.TemporaryDirectory() as directory:
        evidence = Path(directory)
        metadata_path = evidence / 'metadata.json'
        commits_path = evidence / 'commits.json'
        files_path = evidence / 'files.json'
        base_workflows_path = evidence / 'base-workflows'
        head_workflows_path = evidence / 'head-workflows'
        base_workflows_path.mkdir()
        head_workflows_path.mkdir()
        metadata_path.write_text(json.dumps(metadata))
        commits_path.write_text(json.dumps(commits))
        files_path.write_text(json.dumps(files))
        for name, contents in base_workflows.items():
            (base_workflows_path / name).write_text(contents)
        for name, contents in head_workflows.items():
            (head_workflows_path / name).write_text(contents)
        return subprocess.run([
            'python3', str(authorization_script),
            '--metadata', str(metadata_path),
            '--commits', str(commits_path),
            '--files', str(files_path),
            '--expected-commit-count', str(expected_commit_count),
            '--expected-file-count', str(expected_file_count),
            '--latest-homebrew-tap-sha', latest_sha,
            '--base-workflows', str(base_workflows_path),
            '--head-workflows', str(head_workflows_path),
        ], text=True, capture_output=True, check=False).returncode == 0

assert authorized(
    metadata=[publish_dependency],
    files=changed_files_for([publish_dependency]),
    base_workflows=base_workflows_for([publish_dependency]),
)
assert authorized(
    metadata=[auto_merge_dependency],
    files=changed_files_for([auto_merge_dependency]),
    base_workflows=base_workflows_for([auto_merge_dependency]),
)
assert authorized()
assert not authorized(metadata=[])
assert not authorized(metadata=[{
    **publish_dependency,
    'dependencyName': 'actions/checkout',
}])
assert not authorized(metadata=[{
    **publish_dependency,
    'packageEcosystem': 'github-actions',
}])
assert not authorized(commits=[{
    **dependabot_commit,
    'author': {'login': 'maintainer'},
}])
assert not authorized(commits=[{
    **dependabot_commit,
    'commit': {'verification': {'verified': False}},
}])
assert not authorized(expected_commit_count=2)
assert not authorized(expected_file_count=3)
assert not authorized(files=[
    *changed_files_for([publish_dependency, auto_merge_dependency]),
    {
        'filename': 'README.md',
        'status': 'modified',
        'patch': '@@ -1 +1 @@\n-old\n+new',
    },
])
assert not authorized(files=[{
    **changed_files_for([publish_dependency])[0],
    'patch': '@@ -1,2 +1,2 @@\n-    timeout-minutes: 5\n+    timeout-minutes: 10',
}], head_workflows={
    **workflow_contents,
    'release.yml': workflow_contents['release.yml'] + '    timeout-minutes: 10\n',
})
assert not authorized(head_workflows={
    **workflow_contents,
    'auto-merge.yml': workflow_contents['auto-merge.yml'].replace(sha, 'b' * 40),
})
assert not authorized(head_workflows={
    **workflow_contents,
    'release.yml': workflow_contents['release.yml'].replace(sha, 'main'),
})
assert not authorized(head_workflows={'release.yml': workflow_contents['release.yml']})
assert not authorized(head_workflows={
    'release.yml': workflow_contents['auto-merge.yml'],
    'auto-merge.yml': workflow_contents['release.yml'],
})
assert not authorized(head_workflows={
    **workflow_contents,
    'release.yml': workflow_contents['release.yml'].replace('    uses:', '      uses:'),
})
assert not authorized(latest_sha='c' * 40)

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
