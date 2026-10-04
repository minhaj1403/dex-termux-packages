TERMUX_PKG_HOMEPAGE=https://github.com/termux
TERMUX_PKG_DESCRIPTION="GPG public key for the Dex package repository"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=3.14
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_SKIP_SRC_EXTRACT=true
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_ESSENTIAL=true

termux_step_make_install() {
	local GPG_SHARE_DIR="$TERMUX_PREFIX/share/termux-keyring"

	# Delete all existing termux-keyring keys
	rm -rf "$GPG_SHARE_DIR"
	mkdir -p "$GPG_SHARE_DIR"

	# Dex: only the key of the Dex package repository is trusted, since
	# packages from the Termux repositories are built for com.termux
	install -Dm600 "$TERMUX_PKG_BUILDER_DIR/dex.gpg" "$GPG_SHARE_DIR"

	# Create symlinks under all GPG_DIRs to key files under GPG_SHARE_DIR
	for GPG_DIR in "$TERMUX_PREFIX/etc/apt/trusted.gpg.d" "$TERMUX_PREFIX/share/pacman/keyrings"; do
		mkdir -p "$GPG_DIR"
		# Delete keys which have been removed in newer version and their symlink target does not exist
		find "$GPG_DIR" -xtype l -printf 'Deleting removed key: %p\n' -delete
		for GPG_FILE in "$GPG_SHARE_DIR"/*.gpg; do
			if [[ "$GPG_DIR" == *"/apt/"* && "$GPG_FILE" == *"termux-pacman.gpg"* ]]; then
				continue
			fi
			# Create or overwrite key symlink
			ln -sf "$GPG_FILE" "$GPG_DIR/$(basename "$GPG_FILE")"
		done
		# Creation of trusted files
		if [[ "$GPG_DIR" == *"/pacman/"* ]]; then
			echo "998DE27318E867EA976BA877389CEED64573DFCA:4:" > "$GPG_DIR/termux-pacman-trusted"
		fi
	done
}

termux_step_create_debscripts() {
	if [ "$TERMUX_PACKAGE_FORMAT" = "pacman" ]; then
		echo "if [ ! -d $TERMUX_PREFIX/etc/pacman.d/gnupg/ ]; then" > postupg
		echo "  pacman-key --init" >> postupg
		echo "fi" >> postupg
		echo "pacman-key --populate" >> postupg
		echo "post_upgrade" > postinst
	fi
}
