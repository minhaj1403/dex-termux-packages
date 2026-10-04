#!/usr/bin/env bash
# The package-builder image is x86_64 only, so on Apple Silicon it runs under Rosetta, which
# does not implement the openat2 syscall. GNU tar 1.35 needs it to extract into folders, so
# install tar 1.34 from Ubuntu 22.04, which does not use it. Run after the container is created.
set -euo pipefail
docker exec -u root termux-package-builder bash -euc '
	if tar --version | grep -q "tar) 1\.34"; then echo "tar 1.34 already installed"; exit 0; fi
	deb="$(mktemp -d)/tar.deb"
	curl -fsSL -o "$deb" http://archive.ubuntu.com/ubuntu/pool/main/t/tar/tar_1.34+dfsg-1ubuntu0.1.22.04.6_amd64.deb
	dpkg -i --force-downgrade "$deb"
	apt-mark hold tar
	tar --version | head -n 1
'
