#!/usr/bin/env bash

set -e

echo "==== Detecting OS ===="

install_deps_debian() {
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends \
        build-essential autoconf libtool libssl-dev \
        libpcre3-dev libev-dev asciidoc xmlto automake git
}

install_deps_rhel() {
    sudo yum install -y \
        gcc autoconf libtool automake make \
        zlib-devel openssl-devel asciidoc xmlto \
        libev-devel git
}

install_deps_arch() {
    sudo pacman -Sy --noconfirm \
        gcc autoconf libtool automake make \
        zlib openssl asciidoc xmlto git
}

install_deps_alpine() {
    apk add --no-cache \
        gcc autoconf make libtool automake \
        zlib-dev openssl asciidoc xmlto \
        libpcre32 libev-dev g++ linux-headers git
}

# Detect OS
if [ -f /etc/debian_version ]; then
    echo "Detected Debian/Ubuntu"
    install_deps_debian

elif [ -f /etc/redhat-release ]; then
    echo "Detected CentOS/RHEL/Fedora"
    install_deps_rhel

elif grep -qi arch /etc/os-release 2>/dev/null; then
    echo "Detected Arch Linux"
    install_deps_arch

elif [ -f /etc/alpine-release ]; then
    echo "Detected Alpine Linux"
    install_deps_alpine

else
    echo "Unsupported Linux distribution"
    exit 1
fi

echo "==== Cloning simple-obfs ===="

if [ ! -d simple-obfs ]; then
    git clone https://github.com/shadowsocks/simple-obfs.git
fi

cd simple-obfs

echo "==== Updating submodules ===="
git submodule update --init --recursive

echo "==== Building simple-obfs ===="
./autogen.sh
./configure
make

echo "==== Installing simple-obfs ===="
sudo make install

echo "==== Done ===="
