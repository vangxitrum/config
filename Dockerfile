FROM ubuntu:24.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
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
    && rm -rf /var/lib/apt/lists/*

# Create a custom user
ARG USERNAME=tuan
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set the working directory to the user's home
WORKDIR /home/$USERNAME/setup/config

# Copy the configuration files with correct ownership
COPY --chown=$USERNAME:$USERNAME . .

# Switch to the custom user
USER $USERNAME

# Make scripts executable
RUN chmod +x ./init.sh ./scripts/*.sh


# Install Languages (individual steps for better caching/logging)
RUN ./scripts/node.sh
RUN ./scripts/python.sh
RUN ./scripts/luarocks.sh
RUN ./scripts/go.sh

# Install Environment and Tools
RUN ./scripts/docker.sh
RUN ./scripts/zsh.sh
RUN ./scripts/i3.sh
RUN ./scripts/tmux.sh
RUN ./scripts/nvim.sh
RUN ./scripts/ghostty.sh
RUN ./scripts/font.sh

# Run remaining setup from init.sh (Vietnamese input, etc.)
# We skip the scripts we already ran
RUN sed -i '/scripts\/.*\.sh/d' ./init.sh && ./init.sh

# Set default command to interactive bash
CMD ["/bin/bash", "-i"]
