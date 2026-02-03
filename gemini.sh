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

  docker run -it --rm --cpus 4 --memory 1G \
    --group-add "${DOCKER_GID}" \
    --env-file "${HOME}/.gemini/.env" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${HOME}/.gemini:/home/node/.gemini" \
    -v "${HOME}/workspace:/workspace" \
    -v "${HOME}/.docker:/home/node/.docker:ro" \
    -v "${HOME}/.docker/mcp:/home/node/.docker/mcp" \
    -w "/workspace" \
    ghcr.io/stefanbosak/gemini-cli:initial \
    gemini -y "$@"
}

# run
gemini "${@}"
