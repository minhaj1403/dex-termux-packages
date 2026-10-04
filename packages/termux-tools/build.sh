TERMUX_PKG_HOMEPAGE=https://termux.dev/
TERMUX_PKG_DESCRIPTION="Basic system tools for Termux"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.46.0+really1.45.0"
TERMUX_PKG_REVISION=2
TERMUX_PKG_SRCURL=https://github.com/termux/termux-tools/archive/refs/tags/v1.45.0.tar.gz
TERMUX_PKG_SHA256=1ae29b1b875d95cc626dae323b45a2ace759969862d96094b2fa6d13bffe20d2
TERMUX_PKG_ESSENTIAL=true
#TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"
TERMUX_PKG_BREAKS="termux-keyring (<< 1.9)"
TERMUX_PKG_CONFLICTS="procps (<< 3.3.15-2)"
TERMUX_PKG_SUGGESTS="termux-api"

# Some of these packages are not dependencies and used only to ensure
# that core packages are installed after upgrading (we removed busybox
# from essentials).
TERMUX_PKG_DEPENDS="bzip2, coreutils, curl, dash, diffutils, findutils, gawk, grep, gzip, less, procps, psmisc, sed, tar, termux-am (>= 0.8.0), termux-am-socket (>= 1.5.0), termux-core, termux-exec, util-linux, xz-utils, dialog"

# Optional packages that are distributed as part of bootstrap archives.
TERMUX_PKG_RECOMMENDS="ed, dos2unix, inetutils, net-tools, patch, unzip"

termux_step_pre_configure() {
	# Dex: configure uses com.termux paths unless these are set. The classes of the
	# app keep the com.termux namespace, so components are named by it.
	export TERMUX_APP_PACKAGE="$TERMUX_APP__PACKAGE_NAME"
	export TERMUX_BASE_DIR="$TERMUX__ROOTFS"
	export TERMUX_CACHE_DIR="$TERMUX__CACHE_DIR"
	export TERMUX_PREFIX
	export TERMUX_ANDROID_HOME
	sed -i "s|@TERMUX_APP_PACKAGE@/@TERMUX_APP_PACKAGE@\.app\.|@TERMUX_APP_PACKAGE@/$TERMUX_APP__NAMESPACE.app.|g" "$TERMUX_PKG_SRCDIR"/scripts/*.in

	autoreconf -vfi
}

termux_step_post_make_install() {
	# Dex: Termux mirrors serve packages built for com.termux, which do not work
	# here, so the Dex repository is the only mirror
	local mirrors_dir="$TERMUX_PREFIX/etc/termux/mirrors"
	rm -rf "$mirrors_dir"/{asia,chinese_mainland,europe,north_america,oceania,russia}
	cat > "$mirrors_dir/default" <<- EOF
	# This file is sourced by pkg
	# The Dex package repository
	WEIGHT=10
	MAIN="https://minhaj1403.github.io/dex-packages"
	EOF
	TERMUX_PKG_CONFFILES="$(grep -v -E 'etc/termux/mirrors/(asia|chinese_mainland|europe|north_america|oceania|russia)/' "$TERMUX_PKG_BUILDDIR/conffiles")"
}

termux_step_create_debscripts() {
	cat <<- EOF > ./preinst
	$(cat "$TERMUX_PKG_BUILDDIR/preinst")
	EOF
}
