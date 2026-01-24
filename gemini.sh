#!/bin/bash
#
# Google Gemini CLI runner wrapper
#

#
# Docker container Google Gemini CLI wrapper
#
gemini() {
  # extract Docker GID from the system
  export DOCKER_GID=$(getent group docker | cut -d: -f3)

  docker run -it --rm \
    # add obtained docker group from host into container
    --group-add "${DOCKER_GID}" \
    # Google Gemini CLI environment variables
    --env-file "${HOME}/.gemini/.env" \
    # Docker in Docker socket mapping
    -v /var/run/docker.sock:/var/run/docker.sock \
    # Google Gemini CLI configuration storage
    -v "${HOME}/.gemini:/home/node/.gemini" \
    # workspace used by Google Gemini CLI
    -v "${HOME}/workspace:/workspace" \
    # Docker configuration storage
    -v "${HOME}/.docker:/home/node/.docker:ro" \
    # Docker MCP toolkit (optional)
    -v "${HOME}/.docker/mcp:/home/node/.docker/mcp" \
    # set workspace directory
    -w "/workspace" \
    ghcr.io/stefanbosak/gemini-cli:initial \
    # Google Gemini CLI arguments
    gemini -y "$@"
}

# run
gemini "${@}"
