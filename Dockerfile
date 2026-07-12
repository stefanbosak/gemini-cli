# Non-hardened alternative
# FROM node:trixie-slim

# Hardened Node.js (current) [2026-Jan]
FROM dhi.io/node:25-debian13-dev

# Hardened Node.js (LTS) [2026-Jan]
#FROM dhi.io/node:24-debian13-dev

# Build arguments
ARG TARGETARCH
ARG TARGETOS

ARG CONTAINER_USER=user
ARG CONTAINER_GROUP=user

ARG CONTAINER_USER_ID=1000
ARG CONTAINER_GROUP_ID=1000

ARG DEBIAN_FRONTEND=noninteractive

ARG WORKSPACE_ROOT_DIR="/home/${CONTAINER_USER}"

ARG GEMINI_CLI_RELEASE_VERSION="latest"

# OCI Standard Labels
# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.description="Google Gemini CLI container and tooling"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    bash-completion \
    bc \
    ca-certificates \
    curl \
    dnsutils \
    gh \
    git git-lfs \
    gzip \
    iproute2 \
    iputils-ping \
    jq \
    kmod \
    lsof \
    openssh-client \
    pigz \
    procps \
    psmisc \
    python-is-python3 \
    python3-venv \
    ripgrep \
    rsync \
    socat \
    unzip \
    wget \
    whois \
  && apt-get clean \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

COPY "./tools.yaml" "/usr/local/bin/tools.yaml"

# Install development tools and configure Docker-in-Docker
RUN if getent group "${CONTAINER_GROUP_ID}" > /dev/null; then \
      _existing_group="$(getent group "${CONTAINER_GROUP_ID}" | cut -d: -f1)"; \
      if [ "${_existing_group}" != "${CONTAINER_GROUP}" ]; then \
        groupmod -n "${CONTAINER_GROUP}" "${_existing_group}"; \
      fi; \
    else \
      groupadd --gid "${CONTAINER_GROUP_ID}" "${CONTAINER_GROUP}"; \
    fi \
    && if getent passwd "${CONTAINER_USER_ID}" > /dev/null; then \
         _existing_user="$(getent passwd "${CONTAINER_USER_ID}" | cut -d: -f1)"; \
         if [ "${_existing_user}" != "${CONTAINER_USER}" ]; then \
           if [ -d "/home/${_existing_user}" ]; then \
             mv "/home/${_existing_user}" "/home/${CONTAINER_USER}"; \
           fi; \
           usermod -d "/home/${CONTAINER_USER}" -l "${CONTAINER_USER}" "${_existing_user}"; \
         fi; \
       else \
         useradd \
           --uid "${CONTAINER_USER_ID}" \
           --gid "${CONTAINER_GROUP_ID}" \
           --groups "${CONTAINER_GROUP}" \
           -M -d "${WORKSPACE_ROOT_DIR}" \
           -s /bin/bash \
           "${CONTAINER_USER}"; \
       fi \
    && mkdir -p /workspace \
    && chown -R "${CONTAINER_USER}:${CONTAINER_GROUP}" "${WORKSPACE_ROOT_DIR}" /workspace \
  && if [ "${TARGETARCH}" = "amd64" ]; then \
  TOOLBOX_VERSION=$(git ls-remote --refs --sort='version:refname' \
      --tags "https://github.com/googleapis/mcp-toolbox" \
      | awk -F"/" '!($0 ~ /alpha|beta|rc|dev|None|list|nightly|\{/) \
        {print $NF}' | tail -n 1) \
  && curl -sSL -o "/usr/local/bin/toolbox" \
      "https://storage.googleapis.com/mcp-toolbox-for-databases/${TOOLBOX_VERSION}/${TARGETOS}/${TARGETARCH}/toolbox" \
  && chmod +x "/usr/local/bin/toolbox"; \
  fi \
  # Install Google Gemini CLI, Sequential Thinking MCP server
  && npm install -g --no-audit --no-fund @google/gemini-cli@${GEMINI_CLI_RELEASE_VERSION} @modelcontextprotocol/server-sequential-thinking \
  # Install uv (Python package manager)
  && curl -LsSf https://astral.sh/uv/install.sh \
      | UV_INSTALL_DIR=/usr/local/bin sh \
  # Install bun (all-in-one JS toolkit)
  && curl -fsSL https://bun.com/install \
      | BUN_INSTALL=/usr/local bash \
  # Install mdflow
  && BUN_INSTALL=/usr/local bun install --global mdflow \
  # Install Docker-in-Docker
  # Note: DinD via QEMU on ARM64 not supported
  # (ARM64 requires ARM64 kernel from host, not available on AMD64 host)
  && curl -fsSL https://test.docker.com | sh \
  && if ! getent group docker > /dev/null 2>&1; then \
       groupadd -g 999 docker; \
     fi \
  && usermod -aG docker "${CONTAINER_USER}"

# Configure bash shell for subsequent RUN commands
SHELL ["/usr/bin/bash", "-c"]

# Create symlink for tools and setup user environment
RUN GEMINI_PATH="/opt/nodejs/node-v${NODE_VERSION}/bin/gemini" \
  && ln -s "${GEMINI_PATH}" /usr/local/bin/gemini \
  && MCP_SERVER_SEQUENTIAL_THINKING_PATH="/opt/nodejs/node-v${NODE_VERSION}/bin/mcp-server-sequential-thinking" \
  && ln -s "${MCP_SERVER_SEQUENTIAL_THINKING_PATH}" /usr/local/bin/mcp-server-sequential-thinking \
  && cp /etc/skel/.bashrc /home/${CONTAINER_USER}/

# Switch to non-root user
USER "${CONTAINER_USER}:${CONTAINER_GROUP}"

WORKDIR /workspace

CMD ["gemini"]
