#!/usr/bin/env bash
# Publish the debs built in output/ as the signed Dex apt repository, in a clone of
# github.com/minhaj1403/dex-packages, which GitHub Pages serves at
# https://minhaj1403.github.io/dex-packages (the url in sources.list and the mirror of pkg).
#
# Usage: dex/publish-repo.sh [--push]
# Environment: DEX_REPO_DIR (the clone, default ../dex-packages), GNUPGHOME (with the signing
# key, default ~/.dex-repo-gnupg), DEX_REPO_COMMIT_MESSAGE.
set -euo pipefail

PKGS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_DIR="${DEX_REPO_DIR:-$PKGS_DIR/../dex-packages}"
SIGNING_KEY="B85FB5594E0D62B6AEABFF078BB044F94FBCFBA6"
export GNUPGHOME="${GNUPGHOME:-$HOME/.dex-repo-gnupg}"
DIST="stable"
COMPONENT="main"
ARCH="aarch64"

[ -d "$REPO_DIR/.git" ] || { echo "No clone of dex-packages at $REPO_DIR" >&2; exit 1; }
shopt -s nullglob
debs=("$PKGS_DIR"/output/*_{"$ARCH",all}.deb)
[ ${#debs[@]} -gt 0 ] || { echo "No debs in $PKGS_DIR/output" >&2; exit 1; }

# Debs are kept in pool/ by package name, and replaced by newer builds
mkdir -p "$REPO_DIR/pool/$COMPONENT"
for deb in "${debs[@]}"; do
	name="$(basename "$deb")"
	pkg="${name%%_*}"
	dir="$REPO_DIR/pool/$COMPONENT/${pkg:0:1}/$pkg"
	mkdir -p "$dir"
	find "$dir" -name "${pkg}_*.deb" ! -name "$name" -delete
	cp -p "$deb" "$dir/"
done

# Index and Release are generated with apt-ftparchive, in an Ubuntu container if not on Linux
index_script="
	mkdir -p dists/$DIST/$COMPONENT/binary-$ARCH
	apt-ftparchive packages pool/$COMPONENT > dists/$DIST/$COMPONENT/binary-$ARCH/Packages
	gzip -9kf dists/$DIST/$COMPONENT/binary-$ARCH/Packages
	apt-ftparchive \\
		-o APT::FTPArchive::Release::Origin=Dex \\
		-o APT::FTPArchive::Release::Label=Dex \\
		-o APT::FTPArchive::Release::Suite=$DIST \\
		-o APT::FTPArchive::Release::Codename=$DIST \\
		-o APT::FTPArchive::Release::Architectures=$ARCH \\
		-o APT::FTPArchive::Release::Components=$COMPONENT \\
		-o APT::FTPArchive::Release::Description='Packages for Dex (com.dex)' \\
		release dists/$DIST > /tmp/Release
	mv /tmp/Release dists/$DIST/Release
"
if command -v apt-ftparchive >/dev/null; then
	(cd "$REPO_DIR" && bash -euc "$index_script")
else
	docker run --rm --platform linux/arm64 -v "$REPO_DIR:/repo" -w /repo ubuntu:24.04 bash -euc "
		apt-get update -qq >/dev/null && apt-get install -y -qq apt-utils >/dev/null
		$index_script
	"
fi

cd "$REPO_DIR"
rm -f "dists/$DIST/InRelease" "dists/$DIST/Release.gpg"
gpg --batch --yes --local-user "$SIGNING_KEY" --clearsign -o "dists/$DIST/InRelease" "dists/$DIST/Release"
gpg --batch --yes --local-user "$SIGNING_KEY" -abs -o "dists/$DIST/Release.gpg" "dists/$DIST/Release"
# Serve files as they are, without Jekyll
touch .nojekyll

echo "Repository has $(grep -c '^Package:' "dists/$DIST/$COMPONENT/binary-$ARCH/Packages") packages"
if [ "${1:-}" = "--push" ]; then
	git add -A
	git commit -q -m "${DEX_REPO_COMMIT_MESSAGE:-Update packages}" || echo "Nothing changed"
	git push -q origin HEAD
fi
