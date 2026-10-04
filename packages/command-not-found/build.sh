TERMUX_PKG_HOMEPAGE=https://github.com/termux/command-not-found
TERMUX_PKG_DESCRIPTION="Suggest installation of packages in interactive shell sessions"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="Yaksh Bariya <thunder-coding@termux.dev>"
TERMUX_PKG_VERSION=3.5.0
TERMUX_PKG_REVISION=13
TERMUX_PKG_SRCURL=https://github.com/termux/command-not-found/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=1c3681c9c5046a2f9ecaa250361e78cdc30ba2baabc0dfa11accfb6982721b13
TERMUX_PKG_DEPENDS="libc++"

termux_step_pre_configure() {
	export TERMUX_PREFIX
	export TERMUX_SCRIPTDIR
	termux_setup_nodejs

	# Dex: the commands of packages are looked up in the file lists of the Termux
	# repositories, since packages are named the same, but their paths are in
	# com.termux, and the repository of Dex may not have all packages yet. A
	# header is generated for each repository, by name, and all are included.
	export DEX_CNF_REPO_JSON="$TERMUX_PKG_TMPDIR/termux-repo.json"
	cat > "$DEX_CNF_REPO_JSON" <<- EOF
	{
	  "pkg_format": "debian",
	  "packages": {"name": "termux-main", "distribution": "stable", "component": "main", "url": "https://packages-cf.termux.dev/apt/termux-main"},
	  "root-packages": {"name": "termux-root", "distribution": "root", "component": "stable", "url": "https://packages-cf.termux.dev/apt/termux-root"},
	  "x11-packages": {"name": "termux-x11", "distribution": "x11", "component": "main", "url": "https://packages-cf.termux.dev/apt/termux-x11"}
	}
	EOF
	sed -i \
		-e 's|join(TERMUX_SCRIPTDIR, "repo.json")|process.env.DEX_CNF_REPO_JSON|' \
		-e 's|TERMUX_PREFIX.substring(1)|"data/data/com.termux/files/usr"|g' \
		"$TERMUX_PKG_SRCDIR/generate-db.js"
}
