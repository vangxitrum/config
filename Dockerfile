FROM ubuntu:24.04 AS base

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive




# Install basic dependencies
RUN apt-get update && apt-get install -y \
#     curl \
#     wget \
#     git \
#     make \
   sudo
#     ca-certificates \
#     software-properties-common \
#     unzip \
#     flameshot \
#     bsdmainutils
#
# RUN add-apt-repository ppa:ubuntu-vn/ppa && apt-get install -y ibus-unikey
#
# FROM scratch
#
# COPY --from=base / /

WORKDIR /home/setup
#
# Copy the installation script
COPY . .
#
# # Make the script executable
RUN chmod +x ./init.sh

RUN ./init.sh
#
# Run the installation script
# RUN ./scripts/zsh.sh
#
# RUN ./scripts/language.sh
#
# RUN ./scripts/font.sh
#
# RUN ./scripts/i3.sh
#
# RUN ./scripts/nvim.sh
#
# RUN ./scripts/tmux.sh

# Set default command to interactive bash
CMD ["/bin/bash", "-i"]

