#!/bin/bash
# obtain latest Google Gemini CLI version
GEMINI_CLI_VERSION=$(git ls-remote --refs --sort='version:refname' --tags 'https://github.com/google-gemini/gemini-cli' | grep -vE 'alpha|beta|rc|dev|None|list|nightly|\{' | cut -d'/' -f3 | tail -n 1)

# tag latest Google Gemini CLI version (using existing sandbox container image available only in US)
docker tag us-docker.pkg.dev/gemini-code-dev/gemini-cli/sandbox:${GEMINI_CLI_VERSION#v} ghcr.io/stefanbosak/gemini-cli:initial

# push container image into own repository
docker push ghcr.io/stefanbosak/gemini-cli:initial
