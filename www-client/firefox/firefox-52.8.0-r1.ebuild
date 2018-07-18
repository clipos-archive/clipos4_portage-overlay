# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
VIRTUALX_REQUIRED="pgo"
WANT_AUTOCONF="2.1"
MOZ_ESR=1

# This list can be updated with scripts/get_langs.sh from the mozilla overlay
# MOZ_LANGS=( ach af an ar as ast az be bg bn-BD bn-IN br bs ca cs cy da de
# el en en-GB en-US en-ZA eo es-AR es-CL es-ES es-MX et eu fa fi fr
# fy-NL ga-IE gd gl gu-IN he hi-IN hr hsb hu hy-AM id is it ja kk km kn ko
# lt lv mai mk ml mr ms nb-NO nl nn-NO or pa-IN pl pt-BR pt-PT rm ro ru si
# sk sl son sq sr sv-SE ta te th tr uk uz vi xh zh-CN zh-TW )

MOZ_LANGS=( fr en )

# Convert the ebuild version to the upstream mozilla version, used by mozlinguas
MOZ_PV="${PV/_alpha/a}" # Handle alpha for SRC_URI
MOZ_PV="${MOZ_PV/_beta/b}" # Handle beta for SRC_URI
MOZ_PV="${MOZ_PV/_rc/rc}" # Handle rc for SRC_URI

if [[ ${MOZ_ESR} == 1 ]]; then
	# ESR releases have slightly different version numbers
	MOZ_PV="${MOZ_PV}esr"
fi

# Patch version
PATCH="${PN}-52.5-patches-02"
MOZ_HTTP_URI="https://archive.mozilla.org/pub/${PN}/releases"

#MOZCONFIG_OPTIONAL_GTK2ONLY=1
MOZCONFIG_OPTIONAL_WIFI=1

inherit check-reqs flag-o-matic toolchain-funcs eutils gnome2-utils mozconfig-v6.52 pax-utils xdg-utils autotools virtualx mozlinguas-v2 verictl2

DESCRIPTION="Firefox Web Browser"
HOMEPAGE="https://www.mozilla.org/en-US/firefox/"

KEYWORDS="~alpha amd64 ~arm ~arm64 ~ia64 ~ppc ~ppc64 x86 ~amd64-linux ~x86-linux"

SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="bindist eme-free +gmp-autoupdate hardened hwaccel jack pgo rust selinux test"
RESTRICT="!bindist? ( bindist )"
# a decommenter pour debug
# RESTRICT="${RESTRICT} strip"
IUSE+="clip clip-deps clip-devel"

PATCH_URIS=( https://dev.gentoo.org/~{anarchy,axs,polynomial-c}/mozilla/patchsets/${PATCH}.tar.xz )
SRC_URI="${SRC_URI}
	${MOZ_HTTP_URI}/${MOZ_PV}/source/firefox-${MOZ_PV}.source.tar.xz
	${PATCH_URIS[@]}"

ASM_DEPEND=">=dev-lang/yasm-1.1"

RDEPEND="
	jack? ( virtual/jack )
	>=dev-libs/nss-3.28.3
	>=dev-libs/nspr-4.13.1
	selinux? ( sec-policy/selinux-mozilla )"

DEPEND="${RDEPEND}
	pgo? ( >=sys-devel/gcc-4.5 )
	rust? ( virtual/rust )
	amd64? ( ${ASM_DEPEND} virtual/opengl )
	x86? ( ${ASM_DEPEND} virtual/opengl )"

S="${WORKDIR}/firefox-${MOZ_PV}"

QA_PRESTRIPPED="usr/lib*/${PN}/firefox"

BUILD_OBJ_DIR="${S}/ff"

# allow GMP_PLUGIN_LIST to be set in an eclass or
# overridden in the enviromnent (advanced hackers only)
if [[ -z $GMP_PLUGIN_LIST ]]; then
	GMP_PLUGIN_LIST=( gmp-gmpopenh264 gmp-widevinecdm )
fi

pkg_setup() {
	moz_pkgsetup

	# Avoid PGO profiling problems due to enviroment leakage
	# These should *always* be cleaned up anyway
	unset DBUS_SESSION_BUS_ADDRESS \
		DISPLAY \
		ORBIT_SOCKETDIR \
		SESSION_MANAGER \
		XDG_SESSION_COOKIE \
		XAUTHORITY

	if ! use bindist; then
		einfo
		elog "You are enabling official branding. You may not redistribute this build"
		elog "to any users on your network or the internet. Doing so puts yourself into"
		elog "a legal problem with Mozilla Foundation"
		elog "You can disable it by emerging ${PN} _with_ the bindist USE-flag"
	fi

	if use pgo; then
		einfo
		ewarn "You will do a double build for profile guided optimization."
		ewarn "This will result in your build taking at least twice as long as before."
	fi

	if use rust; then
		einfo
		ewarn "This is very experimental, should only be used by those developing firefox."
	fi
}

pkg_pretend() {
	# Ensure we have enough disk space to compile
	if use pgo || use debug || use test ; then
		CHECKREQS_DISK_BUILD="8G"
	else
		CHECKREQS_DISK_BUILD="4G"
	fi
	check-reqs_pkg_setup
}

src_unpack() {
	unpack ${A}

	# Unpack language packs
	mozlinguas_src_unpack
}

src_prepare() {
	# Apply our patches
	rm -f "${WORKDIR}"/firefox/2007_fix_nvidia_latest.patch
	# clip: eapply not available in eapi 5
	# eapply "${WORKDIR}/firefox"
	EPATCH_SUFFIX="patch" \
	EPATCH_FORCE="yes" \
	epatch "${WORKDIR}/firefox"

	# Enable gnomebreakpad
	if use debug ; then
		sed -i -e "s:GNOME_DISABLE_CRASH_DIALOG=1:GNOME_DISABLE_CRASH_DIALOG=0:g" \
			"${S}"/build/unix/run-mozilla.sh || die "sed failed!"
	fi

	# Drop -Wl,--as-needed related manipulation for ia64 as it causes ld sefgaults, bug #582432
	if use ia64 ; then
		sed -i \
		-e '/^OS_LIBS += no_as_needed/d' \
		-e '/^OS_LIBS += as_needed/d' \
		"${S}"/widget/gtk/mozgtk/gtk2/moz.build \
		"${S}"/widget/gtk/mozgtk/gtk3/moz.build \
		|| die "sed failed to drop --as-needed for ia64"
	fi

	# Ensure that our plugins dir is enabled as default
	sed -i -e "s:/usr/lib/mozilla/plugins:${CPREFIX:-/usr}/lib/nsbrowser/plugins:" \
		"${S}"/xpcom/io/nsAppFileLocationProvider.cpp || die "sed failed to replace plugin path for 32bit!"
	sed -i -e "s:/usr/lib64/mozilla/plugins:${CPREFIX:-/usr}/lib64/nsbrowser/plugins:" \
		"${S}"/xpcom/io/nsAppFileLocationProvider.cpp || die "sed failed to replace plugin path for 64bit!"

	# Fix sandbox violations during make clean, bug 372817
	sed -e "s:\(/no-such-file\):${T}\1:g" \
		-i "${S}"/config/rules.mk \
		-i "${S}"/nsprpub/configure{.in,} \
		|| die

	# Don't exit with error when some libs are missing which we have in
	# system.
	sed '/^MOZ_PKG_FATAL_WARNINGS/s@= 1@= 0@' \
		-i "${S}"/browser/installer/Makefile.in || die

	# Don't error out when there's no files to be removed:
	sed 's@\(xargs rm\)$@\1 -f@' \
		-i "${S}"/toolkit/mozapps/installer/packager.mk || die

	# Keep codebase the same even if not using official branding
	sed '/^MOZ_DEV_EDITION=1/d' \
		-i "${S}"/browser/branding/aurora/configure.sh || die

	# Allow user to apply any additional patches without modifing ebuild
	# eapply_user
	# reecrit pour eapi=5 :

	epatch_user

	if use clip && use !clip-devel; then
		epatch "${FILESDIR}"/mozilla-${PN}-3.5.3-disable-extensions.patch || die "epatch failed"
	fi

	if use clip; then
		# Force file association through mimetypes (refresh list)
		ebegin "Generating mimeTypes.rdf file"
		sh "${FILESDIR}/clip/makeMimeTypes.sh" > "${S}/mimeTypes.rdf" || die
		eend $?

		# Suppress health report
		sed -i -e 's/^MOZ_SERVICES_HEALTHREPORT/# MOZ_SERVICES_HEALTHREPORT/g' \
			"${S}/browser/confvars.sh" || die "sed failed to comment MOZ_SERVICES_HEALTHREPORT in browser/confvars.sh"

		# Suppress telemetry reporting
		sed -i -e 's/^export MOZ_TELEMETRY_REPORTING/# export MOZ_TELEMETRY_REPORTING/g' \
			"${S}/browser/config/mozconfigs/linux32/common-opt" || die "sed failed to comment MOZ_TELEMETRY_REPORTING in browser/config/mozconfig/linux32/common-opt"

		sed -i -e 's/^export MOZ_TELEMETRY_REPORTING/# export MOZ_TELEMETRY_REPORTING/g' \
			"${S}/browser/config/mozconfigs/linux64/common-opt" || die "sed failed to comment MOZ_TELEMETRY_REPORTING in browser/config/mozconfig/linux64/common-opt"

		sed -i -e 's/^export MOZ_TELEMETRY_REPORTING/# export MOZ_TELEMETRY_REPORTING/g' \
			"${S}/browser/config/mozconfigs/macosx-universal/common-opt" || die "sed failed to comment MOZ_TELEMETRY_REPORTING in browser/config/mozconfig/macosx-universal/common-opt"

		# Patch the code to remove data reporting
		epatch "${FILESDIR}/mozilla-${PN}-52.3.0-clip-disable-reporting-in-code.patch"
		# Patch the configure.in to remove data reporting
		epatch "${FILESDIR}/mozilla-${PN}-52.3.0-clip-disable-reporting-in-configurations.patch"
		epatch "${FILESDIR}/mozilla-${PN}-52.3.0-clip-disable-signature-check-for-clip-extension.patch"
		epatch "${FILESDIR}/mozilla-${PN}-52.3.0-clip-disable-extension-installation.patch"
		epatch "${FILESDIR}/mozilla-${PN}-52.3.0-clip-disable-bootstrapped-extension-loading.patch"
		
		# a decommenter pour debug
		# epatch "${FILESDIR}/debug.patch"
	fi

	if use clip && use bindist; then
		einfo "Copying clip icons"
		cp -r "${FILESDIR}/clip/icon/"* "${S}/browser/branding/unofficial/"
		cp -r "${FILESDIR}/clip/icon/"* "${S}/browser/branding/nightly/"
	fi
	# Autotools configure is now called old-configure.in
	# This works because there is still a configure.in that happens to be for the
	# shell wrapper configure script
	eautoreconf old-configure.in

	# Must run autoconf in js/src
	cd "${S}"/js/src || die
	eautoconf old-configure.in

	# Need to update jemalloc's configure
	cd "${S}"/memory/jemalloc/src || die
	WANT_AUTOCONF= eautoconf
}

src_configure() {
	MOZILLA_FIVE_HOME="${CPREFIX:-/usr}/$(get_libdir)/${PN}"
	MEXTENSIONS="default"
	# Google API keys (see http://www.chromium.org/developers/how-tos/api-keys)
	# Note: These are for Gentoo Linux use ONLY. For your own distribution, please
	# get your own set of keys.
	_google_api_key=AIzaSyDEAOvatFo0eTgsV_ZlEzx0ObmepsMzfAc

	####################################
	#
	# mozconfig, CFLAGS and CXXFLAGS setup
	#
	####################################

	mozconfig_init
	mozconfig_config

	# enable JACK, bug 600002
	mozconfig_use_enable jack

	use eme-free && mozconfig_annotate '+eme-free' --disable-eme

	# It doesn't compile on alpha without this LDFLAGS
	use alpha && append-ldflags "-Wl,--no-relax"

	# Add full relro support for hardened
	use hardened && append-ldflags "-Wl,-z,relro,-z,now"

	# Only available on mozilla-overlay for experimentation -- Removed in Gentoo repo per bug 571180
	#use egl && mozconfig_annotate 'Enable EGL as GL provider' --with-gl-provider=EGL

	# Setup api key for location services
	echo -n "${_google_api_key}" > "${S}"/google-api-key
	mozconfig_annotate '' --with-google-api-keyfile="${S}/google-api-key"

	mozconfig_annotate '' --enable-extensions="${MEXTENSIONS}"

	# pour le debug dans clip :
	# mozconfig_annotate '' --enable-debug
	# mozconfig_annotate '' --enable-debug-label
	# mozconfig_annotate '' --disable-optimize
	# mozconfig_annotate '' --disable-tests

	# mozconfig_use_enable rust
	mozconfig_annotate '' --with-default-mozilla-five-home=${MOZILLA_FIVE_HOME}

	# Allow for a proper pgo build
	if use pgo; then
		echo "mk_add_options PROFILE_GEN_SCRIPT='EXTRA_TEST_ARGS=10 \$(MAKE) -C \$(MOZ_OBJDIR) pgo-profile-run'" >> "${S}"/.mozconfig
	fi

	echo "mk_add_options MOZ_OBJDIR=${BUILD_OBJ_DIR}" >> "${S}"/.mozconfig
	echo "mk_add_options XARGS=/usr/bin/xargs" >> "${S}"/.mozconfig

	# Finalize and report settings
	mozconfig_final

	if use clip ; then
		append-cxxflags -fstack-protector
	else
		if [[ $(gcc-major-version) -lt 4 ]]; then
			append-cxxflags -fno-stack-protector
		fi
	fi
	
	# pour le debug dans clip
	# append-cxxflags -g

	# workaround for funky/broken upstream configure...
	SHELL="${SHELL:-${EPREFIX%/}/bin/bash}" \
	emake -f client.mk configure
}

src_compile() {
	if use pgo; then
		addpredict /root
		addpredict /etc/gconf
		# Reset and cleanup environment variables used by GNOME/XDG
		gnome2_environment_reset

		# Firefox tries to use dri stuff when it's run, see bug 380283
		shopt -s nullglob
		cards=$(echo -n /dev/dri/card* | sed 's/ /:/g')
		if test -z "${cards}"; then
			cards=$(echo -n /dev/ati/card* /dev/nvidiactl* | sed 's/ /:/g')
			if test -n "${cards}"; then
				# Binary drivers seem to cause access violations anyway, so
				# let's use indirect rendering so that the device files aren't
				# touched at all. See bug 394715.
				export LIBGL_ALWAYS_INDIRECT=1
			fi
		fi
		shopt -u nullglob
		[[ -n "${cards}" ]] && addpredict "${cards}"

		# premiere ligne pour clip
		CC="$(tc-getCC)" CXX="$(tc-getCXX)" LD="$(tc-getLD)" \
		MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX%/}/bin/bash}" \
		virtx emake -f client.mk profiledbuild || die "virtx emake failed"
	else
		# premiere ligne pour clip
		CC="$(tc-getCC)" CXX="$(tc-getCXX)" LD="$(tc-getLD)" \
		MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX%/}/bin/bash}" \
		emake -f client.mk realbuild
	fi

}

src_install() {
	MOZILLA_FIVE_HOME="${CPREFIX:-/usr}/$(get_libdir)/${PN}"
	cd "${BUILD_OBJ_DIR}" || die

	# Pax mark xpcshell for hardened support, only used for startupcache creation.
	pax-mark m "${BUILD_OBJ_DIR}"/dist/bin/xpcshell

	# Add our default prefs for firefox
	cp "${FILESDIR}"/gentoo-default-prefs.js-1 \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die

	mozconfig_install_prefs \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js"

	# Augment this with hwaccel prefs
	if use hwaccel ; then
		cat "${FILESDIR}"/gentoo-hwaccel-prefs.js-1 >> \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die
	fi

	echo "pref(\"extensions.autoDisableScopes\", 3);" >> \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die

	local plugin
	use gmp-autoupdate || use eme-free || for plugin in "${GMP_PLUGIN_LIST[@]}" ; do
		echo "pref(\"media.${plugin}.autoupdate\", false);" >> \
			"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
			|| die
	done

	MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX%/}/bin/bash}" \
	emake DESTDIR="${D}" install

	# Install language packs
	mozlinguas_src_install

	local size sizes icon_path icon name
	if use bindist; then
		if use clip; then
			sizes="16 32 48 64 256"
			# The unofficial icons are f* ugly, and the unofficial
			# name will be confusing to end-users - let's do as
			# much as we can
			icon_path="${FILESDIR}/clip/icon"
			icon="firefox"
			name="Firefox"
		else
			sizes="16 32 48"
			icon_path="${S}/browser/branding/aurora"
			# Firefox's new rapid release cycle means no more codenames
			# Let's just stick with this one...
			icon="aurora"
			name="Aurora"

		# Override preferences to set the MOZ_DEV_EDITION defaults, since we
		# don't define MOZ_DEV_EDITION to avoid profile debaucles.
		# (source: browser/app/profile/firefox.js)
		cat >>"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" <<PROFILE_EOF
pref("app.feedback.baseURL", "https://input.mozilla.org/%LOCALE%/feedback/firefoxdev/%VERSION%/");
sticky_pref("lightweightThemes.selectedThemeID", "firefox-devedition@mozilla.org");
sticky_pref("browser.devedition.theme.enabled", true);
sticky_pref("devtools.theme", "dark");
PROFILE_EOF
		fi
	else
		sizes="16 22 24 32 256"
		icon_path="${S}/browser/branding/official"
		icon="${PN}"
		name="Mozilla Firefox"
	fi

	# Install icons and .desktop for menu entry
	for size in ${sizes}; do
		insinto "/usr/share/icons/hicolor/${size}x${size}/apps"
		newins "${icon_path}/default${size}.png" "${icon}.png"
	done
	# The 128x128 icon has a different name
	insinto "/usr/share/icons/hicolor/128x128/apps"
	newins "${icon_path}/mozicon128.png" "${icon}.png"
	# Install a 48x48 icon into /usr/share/pixmaps for legacy DEs
	newicon "${icon_path}/content/icon48.png" "${icon}.png"
	newmenu "${FILESDIR}/icon/${PN}.desktop" "${PN}.desktop"
	sed -i -e "s:@NAME@:${name}:" -e "s:@ICON@:${icon}:" \
		"${ED}${CPREFIX:-/usr}/share/applications/${PN}.desktop" || die

	# Add StartupNotify=true bug 237317
	if use startup-notification ; then
		echo "StartupNotify=true"\
			 >> "${ED}${CPREFIX:-/usr}/share/applications/${PN}.desktop" \
			|| die
	fi

	# Required in order to use plugins and even run firefox on hardened.
	pax-mark m "${ED}"${MOZILLA_FIVE_HOME}/{firefox,firefox-bin,plugin-container}

	if use clip; then
		# Default settings
		insinto "${MOZILLA_FIVE_HOME}/defaults/preferences"
		doins "${FILESDIR}"/clip/local-settings.js
		insinto "${MOZILLA_FIVE_HOME}"
		doins "${FILESDIR}"/clip/mozilla.cfg
		sed -i -e "s/FIREFOX_VERSION/${PV}/g" \
			"${ED}/${MOZILLA_FIVE_HOME}/defaults/preferences/local-settings.js" \
			"${ED}/${MOZILLA_FIVE_HOME}/mozilla.cfg" \
			|| die
		echo "pref(\"general.useragent.extra.firefox\", \"Firefox/${PV}\");" \
			>> "${ED}${MOZILLA_FIVE_HOME}/defaults/preferences/local-settings.js"

		# Localization
		local lang=${linguas[0]}
		if [[ -n ${lang} && ${lang} != "en" ]]; then
			elog "Setting default locale to ${lang}"
			echo "pref(\"general.useragent.locale\", \"${lang}\");" \
				>> "${ED}${MOZILLA_FIVE_HOME}/defaults/preferences/local-settings.js"
		fi

		insinto "${MOZILLA_FIVE_HOME}/defaults/profile"
		doins "${S}/mimeTypes.rdf"

		for ext in dic aff; do
			dodir ${MOZILLA_FIVE_HOME}/dictionaries
			dosym /usr/share/myspell/fr_FR.${ext} \
						${MOZILLA_FIVE_HOME}/dictionaries/fr-FR.${ext}
			dosym /usr/share/myspell/fr_FR.${ext} \
						${MOZILLA_FIVE_HOME}/dictionaries/fr_FR.${ext}
		done
		
		# Needed for menu compatibility
		dosym /usr/share/applications/firefox.desktop \
			/usr/share/applications/mozillafirefox.desktop

		# Needed for compatibily with e.g. old KDE config.
		dosym /usr/bin/firefox /usr/bin/firefox.sh
		
		# Plugin-container - use wrapper script to export proper LD_LIBRARY_PATH
		if [[ -n "${CPREFIX}" ]]; then
			mv "${ED}${MOZILLA_FIVE_HOME}/plugin-container" \
				"${ED}${MOZILLA_FIVE_HOME}/plugin-container-bin"
			exeinto "${MOZILLA_FIVE_HOME}"
			newexe "${FILESDIR}/plugin-container.in" "plugin-container"
			sed -i -e "s:@PREFIX@:${CPREFIX}:" \
				"${ED}${MOZILLA_FIVE_HOME}/plugin-container"				
		fi		
		
	fi

}

pkg_preinst() {
	gnome2_icon_savelist

	# if the apulse libs are available in MOZILLA_FIVE_HOME then apulse
	# doesn't need to be forced into the LD_LIBRARY_PATH
	if use pulseaudio && has_version ">=media-sound/apulse-0.1.9" ; then
		einfo "APULSE found - Generating library symlinks for sound support"
		local lib
		pushd "${ED}"${MOZILLA_FIVE_HOME} &>/dev/null || die
		for lib in ../apulse/libpulse{.so{,.0},-simple.so{,.0}} ; do
			# a quickpkg rolled by hand will grab symlinks as part of the package,
			# so we need to avoid creating them if they already exist.
			if ! [ -L ${lib##*/} ]; then
				ln -s "${lib}" ${lib##*/} || die
			fi
		done
		popd &>/dev/null || die
	fi
}

pkg_postinst() {
	# Update mimedb for the new .desktop file
	xdg_desktop_database_update
	gnome2_icon_cache_update

	if ! use gmp-autoupdate && ! use eme-free ; then
		elog "USE='-gmp-autoupdate' has disabled the following plugins from updating or"
		elog "installing into new profiles:"
		local plugin
		for plugin in "${GMP_PLUGIN_LIST[@]}"; do elog "\t ${plugin}" ; done
	fi

	if use pulseaudio && has_version ">=media-sound/apulse-0.1.9" ; then
		elog "Apulse was detected at merge time on this system and so it will always be"
		elog "used for sound.  If you wish to use pulseaudio instead please unmerge"
		elog "media-sound/apulse."
	fi
}

pkg_postrm() {
	gnome2_icon_cache_update
}

pkg_predeb() {
	local MOZILLA_FIVE_HOME="${CPREFIX:-/usr}/$(get_libdir)/${PN}"
	patchelf --set-rpath \
	"${CPREFIX:-/usr}/lib/gcc-lib5:${CPREFIX:-/usr}/lib:${CPREFIX:-/usr}/lib/firefox" \
	"${ED}${MOZILLA_FIVE_HOME}/firefox-bin" || die "Need dev-util/patchelf for ${f}"
	patchelf --set-rpath \
	"${CPREFIX:-/usr}/lib/gcc-lib5:${CPREFIX:-/usr}/lib:${CPREFIX:-/usr}/lib/firefox" \
	"${ED}${MOZILLA_FIVE_HOME}/firefox" || die "Need dev-util/patchelf for ${f}"
	patchelf --set-rpath \
	"${CPREFIX:-/usr}/lib/gcc-lib5:${CPREFIX:-/usr}/lib:${CPREFIX:-/usr}/lib/firefox" \
	"${ED}${MOZILLA_FIVE_HOME}/plugin-container-bin" || die "Need dev-util/patchelf for ${f}"
	
	for f in $(find "${D}" -name '*.so*') ; do
	    patchelf --set-rpath \
		"${CPREFIX:-/usr}/lib/gcc-lib5:${CPREFIX:-/usr}/lib:${CPREFIX:-/usr}/lib/firefox" \
	    "${f}" || die "Need dev-util/patchelf for ${f}"
	done

	doverictld2  ${MOZILLA_FIVE_HOME}/firefox-bin e - - - c 
	doverictld2  ${MOZILLA_FIVE_HOME}/firefox e - - - c 
	doverictld2  ${MOZILLA_FIVE_HOME}/plugin-container-bin e - - - c
}
