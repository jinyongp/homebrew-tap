#!/usr/bin/env python3
"""Authorize a Dependabot update of the public homebrew-tap workflows."""

import argparse
import json
import re
from pathlib import Path


ALLOWED_DEPENDENCIES = {
    'jinyongp/homebrew-tap/.github/workflows/publish-formula.yml',
    'jinyongp/homebrew-tap/.github/workflows/auto-merge-homebrew-tap.yml',
}
USES_LINE = re.compile(
    r'^\s*uses:\s+(?P<value>"[^"]+"|\'[^\']+\'|[^#\s]+)(?:\s+#.*)?$'
)
FULL_SHA = re.compile(r'[0-9a-f]{40}')


def reject(message):
    raise SystemExit(f'homebrew-tap update rejected: {message}')


def read_json(path):
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        reject(f'cannot read {path}: {error}')


def validate_metadata(metadata):
    if not isinstance(metadata, list) or not metadata:
        reject('Dependabot metadata must contain at least one dependency')
    if any(item.get('packageEcosystem') != 'github_actions' for item in metadata):
        reject('dependency is not from the GitHub Actions ecosystem')
    dependencies = {item.get('dependencyName') for item in metadata}
    if not dependencies <= ALLOWED_DEPENDENCIES:
        reject('PR contains dependencies outside the homebrew-tap workflow contract')
    return dependencies


def validate_commits(commits, expected_count):
    if not isinstance(commits, list) or len(commits) != expected_count:
        reject('complete PR commit history was not retrieved')
    if not commits:
        reject('PR contains no commits')
    for commit in commits:
        author = commit.get('author') or {}
        verification = (commit.get('commit') or {}).get('verification') or {}
        if author.get('login') != 'dependabot[bot]' or verification.get('verified') is not True:
            reject('every PR commit must be authored and verified by Dependabot')


def parse_workflow_ref(line, source):
    match = USES_LINE.fullmatch(line)
    if not match:
        reject(f'cannot parse homebrew-tap workflow reference in {source}')
    value = match.group('value').strip('"\'')
    dependency, separator, ref = value.rpartition('@')
    if not separator or dependency not in ALLOWED_DEPENDENCIES:
        reject(f'unsupported homebrew-tap workflow reference in {source}')
    if FULL_SHA.fullmatch(ref) is None:
        reject(f'homebrew-tap workflow reference in {source} is not a full commit SHA')
    return dependency, ref


def validate_changed_files(files, expected_count):
    if not isinstance(files, list) or len(files) != expected_count:
        reject('complete PR file list was not retrieved')
    if not files:
        reject('PR changes no files')
    for changed_file in files:
        filename = changed_file.get('filename', '')
        if (changed_file.get('status') != 'modified' or
                not filename.startswith('.github/workflows/') or
                Path(filename).suffix not in {'.yml', '.yaml'}):
            reject(f'PR changes unsupported file: {filename}')
        patch = changed_file.get('patch')
        if not isinstance(patch, str):
            reject(f'PR patch is unavailable for {filename}')


def normalize_workflows(workflows):
    refs = {dependency: [] for dependency in ALLOWED_DEPENDENCIES}
    normalized = {}
    for path in sorted(workflows.iterdir()):
        if path.suffix not in {'.yml', '.yaml'}:
            continue
        normalized_lines = []
        for line in path.read_text().splitlines(keepends=True):
            if line.lstrip().startswith('#') or 'jinyongp/homebrew-tap/.github/workflows/' not in line:
                normalized_lines.append(line)
                continue
            content = line.rstrip('\r\n')
            line_ending = line[len(content):]
            dependency, ref = parse_workflow_ref(content, path.name)
            refs[dependency].append(ref)
            normalized_lines.append(content.replace(f'@{ref}', '@<homebrew-tap-sha>', 1) + line_ending)
        normalized[path.name] = ''.join(normalized_lines)
    return normalized, refs


def validate_workflows(base_workflows, head_workflows, metadata_dependencies,
                       approved_homebrew_tap_sha):
    base_normalized, base_refs = normalize_workflows(base_workflows)
    head_normalized, head_refs = normalize_workflows(head_workflows)
    if base_normalized != head_normalized:
        reject('workflow content changed beyond homebrew-tap commit SHAs')
    if any(not dependency_refs for dependency_refs in head_refs.values()):
        reject('both homebrew-tap reusable workflows must be referenced')
    changed_dependencies = {
        dependency for dependency in ALLOWED_DEPENDENCIES
        if base_refs[dependency] != head_refs[dependency]
    }
    if changed_dependencies != metadata_dependencies:
        reject('workflow changes do not match Dependabot dependency metadata')
    all_refs = [ref for dependency_refs in head_refs.values() for ref in dependency_refs]
    if len(set(all_refs)) != 1:
        reject('homebrew-tap workflows must use the same commit SHA')
    if all_refs[0] != approved_homebrew_tap_sha:
        reject('homebrew-tap workflows must use the latest automation release SHA')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--metadata', type=Path, required=True)
    parser.add_argument('--commits', type=Path, required=True)
    parser.add_argument('--files', type=Path, required=True)
    parser.add_argument('--expected-commit-count', type=int, required=True)
    parser.add_argument('--expected-file-count', type=int, required=True)
    parser.add_argument('--approved-homebrew-tap-sha', required=True)
    parser.add_argument('--base-workflows', type=Path, required=True)
    parser.add_argument('--head-workflows', type=Path, required=True)
    args = parser.parse_args()

    if FULL_SHA.fullmatch(args.approved_homebrew_tap_sha) is None:
        reject('approved homebrew-tap automation revision is not a full commit SHA')
    dependencies = validate_metadata(read_json(args.metadata))
    validate_commits(read_json(args.commits), args.expected_commit_count)
    validate_changed_files(read_json(args.files), args.expected_file_count)
    validate_workflows(
        args.base_workflows, args.head_workflows, dependencies,
        args.approved_homebrew_tap_sha,
    )


if __name__ == '__main__':
    main()
