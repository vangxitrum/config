# ==========================================
# STAGE 1: Base Operating System
# ==========================================
FROM ubuntu:24.04 AS base

LABEL maintainer="vangxitrum"
LABEL description="Modular Development Environment"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Fcitx5 Environment Variables
ENV GTK_IM_MODULE=fcitx \
    QT_IM_MODULE=fcitx \
    XMODIFIERS=@im=fcitx \
    SHELL=/bin/zsh

# Install core system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ripgrep \
    wget \
    git \
    make \
    sudo \
    ca-certificates \
    software-properties-common \
    xclip \
    unzip \
    flameshot \
    bsdmainutils \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# ==========================================
# STAGE 2: User Configuration
# ==========================================
ARG USERNAME=tuan
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN if getent group $USER_GID > /dev/null; then \
        groupmod -n $USERNAME $(getent group $USER_GID | cut -d: -f1); \
    else \
        groupadd --gid $USER_GID $USERNAME; \
    fi \
    && if getent passwd $USER_UID > /dev/null; then \
        usermod -l $USERNAME -m -d /home/$USERNAME $(getent passwd $USER_UID | cut -d: -f1); \
    else \
        useradd --uid $USER_UID --gid $USER_GID -m $USERNAME; \
    fi \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Prepare workspace
RUN mkdir -p /home/$USERNAME/setup/config && chown -R $USERNAME:$USERNAME /home/$USERNAME/setup
WORKDIR /home/$USERNAME/setup/config

# ==========================================
# STAGE 3: Context & Script Setup
# ==========================================
# Copy configuration files first for script execution
COPY --chown=$USERNAME:$USERNAME . .

# Ensure all scripts are executable
RUN chmod +x ./init.sh ./scripts/*.sh

# Switch to the custom user for installation steps
USER $USERNAME

# ==========================================
# STAGE 4: Development Runtimes (Languages)
# ==========================================
RUN ./scripts/node.sh
RUN ./scripts/python.sh
RUN ./scripts/luarocks.sh
RUN ./scripts/go.sh

# ==========================================
# STAGE 5: Environment & Workspace Tools
# ==========================================
RUN ./scripts/zsh.sh
RUN ./scripts/docker.sh
RUN ./scripts/i3.sh
RUN ./scripts/tmux.sh
RUN ./scripts/nvim.sh
RUN ./scripts/ghostty.sh
RUN ./scripts/font.sh
RUN ./scripts/dunst.sh
RUN ./scripts/s3cmd.sh
RUN ./scripts/fcitx5.sh

# ==========================================
# STAGE 6: Final Initialization & Entrypoint
# ==========================================
# Run remaining setup from init.sh (Vietnamese input, etc.)
# Filters out scripts already run as RUN steps for better caching
RUN <<EOF >> ~/.profile

# Fcitx5
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF


# Set default command
CMD ["/bin/zsh", "-i"]
