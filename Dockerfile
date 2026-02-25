FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Build Dependencies
RUN apt-get update && apt-get install -y \
    build-essential wget xz-utils pkg-config \
    libglib2.0-dev libncursesw5-dev libslang2-dev \
    libssh2-1-dev libssl-dev file \
    && rm -rf /var/lib/apt/lists/*

# 2. Get AppImage tools
RUN wget -O /usr/local/bin/linuxdeploy https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage \
    && chmod +x /usr/local/bin/linuxdeploy

# 3. Copy YOUR files into the build context
COPY build_mc.sh /build_mc.sh
COPY ./files/mc.desktop /mc.desktop
COPY ./files/mc.png /mc.png
RUN chmod +x /build_mc.sh

WORKDIR /build
CMD ["/build_mc.sh"]

