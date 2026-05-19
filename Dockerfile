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

WORKDIR /home/setup

# Copy the configuration files
COPY . .

# Make scripts executable
RUN chmod +x ./init.sh ./scripts/*.sh

# Run the initialization script
RUN ./init.sh

# Set default command to interactive bash
CMD ["/bin/bash", "-i"]
