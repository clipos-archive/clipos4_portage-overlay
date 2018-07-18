# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit multilib eutils versionator pax-utils verictl2

DESCRIPTION="ICA Client for Citrix Presentation servers"
DESCRIPTION_FR="Client de déport d'affichage CITRIX"
CATEGORY_FR="Réseau"
HOMEPAGE="http://www.citrix.com/"
SRC_URI="amd64? ( linuxx64-${PV}.tar.gz )
	x86? ( linuxx86-${PV}.tar.gz )"

LICENSE="icaclient"
SLOT="0"
KEYWORDS="-* ~amd64 x86"
IUSE="nsplugin linguas_de linguas_es linguas_fr linguas_ja linguas_zh_CN clip"
# change added to this ebuild: remove the fetch and mirror in RESTRICT
RESTRICT="strip userpriv"

ICAROOT="/opt/Citrix/ICAClient"

QA_PREBUILT="${ICAROOT#/}/*"

RDEPEND="dev-libs/atk
	dev-libs/glib
	dev-libs/libxml2
	media-fonts/font-adobe-100dpi
	media-fonts/font-misc-misc
	media-fonts/font-cursor-misc
	media-fonts/font-xfree86-type1
	media-fonts/font-misc-ethiopic
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	media-libs/gst-plugins-base
	media-libs/gstreamer
	media-libs/libcanberra[gtk]
	media-libs/libogg
	!clip? ( media-libs/libpng:1.2 )
	clip? ( media-libs/libpng12 )
	media-libs/libvorbis
	media-libs/speex
	virtual/krb5
	x11-libs/cairo
	x11-libs/gdk-pixbuf
	x11-libs/gtk+:2
	x11-libs/libX11
	x11-libs/libXaw
	x11-libs/libXext
	x11-libs/libXinerama
	x11-libs/libXmu
	x11-libs/libXrender
	x11-libs/libXt
	x11-libs/pango
	x11-terms/xterm"
DEPEND=""

if use amd64 ; then
	ICAARCH=linuxx64
elif use x86 ; then
	ICAARCH=linuxx86
fi
S="${WORKDIR}/${ICAARCH}/${ICAARCH}.cor"

pkg_nofetch() {
	elog "Download the client file ${A} from
	http://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-13-2.html"
	elog "and place it in ${DISTDIR:-/usr/portage/distfiles}."
}

pkg_setup() {
	if use clip; then
		ICAROOT="${CPREFIX:-/usr}/lib/ICAClient"
		QA_TEXTRELS="${ICAROOT#/}/VDFLASH2.DLL
			${ICAROOT#/}/lib/libcoreavc_sdk.so"

		QA_EXECSTACK="${ICAROOT#/}/PDCRYPT2.DLL
			${ICAROOT#/}/lib/libcoreavc_sdk.so"

		QA_FLAGS_IGNORED="${ICAROOT#/}/npica.so
			${ICAROOT#/}/AUDALSA.DLL
			${ICAROOT#/}/ServiceRecord
			${ICAROOT#/}/VDGSTCAM.DLL
			${ICAROOT#/}/VDFLASH2.DLL
			${ICAROOT#/}/PrimaryAuthManager
			${ICAROOT#/}/VDMM.DLL
			${ICAROOT#/}/CHARICONV.DLL
			${ICAROOT#/}/VDSCARD.DLL
			${ICAROOT#/}/PDCRYPT1.DLL
			${ICAROOT#/}/VDMSSPI.DLL
			${ICAROOT#/}/PDCRYPT2.DLL
			${ICAROOT#/}/VDHSSPI.DLL
			${ICAROOT#/}/selfservice
			${ICAROOT#/}/libctxssl.so
			${ICAROOT#/}/util/gst_read
			${ICAROOT#/}/util/nslaunch
			${ICAROOT#/}/util/xcapture
			${ICAROOT#/}/util/configmgr
			${ICAROOT#/}/util/gst_aud_play
			${ICAROOT#/}/util/conncenter
			${ICAROOT#/}/util/lurdump
			${ICAROOT#/}/util/libgstflatstm.so
			${ICAROOT#/}/util/gst_aud_read
			${ICAROOT#/}/util/echo_cmd
			${ICAROOT#/}/util/gst_play
			${ICAROOT#/}/util/pnabrowse
			${ICAROOT#/}/util/what
			${ICAROOT#/}/lib/ctxh264_fb.so
			${ICAROOT#/}/lib/libkcpm.so
			${ICAROOT#/}/lib/libkcph.so
			${ICAROOT#/}/lib/libcoreavc_sdk.so
			${ICAROOT#/}/lib/libAMSDK.so
			${ICAROOT#/}/lib/UIDialogLib.so
			${ICAROOT#/}/AUDOSS.DLL
			${ICAROOT#/}/AuthManagerDaemon
			${ICAROOT#/}/wfica
			${ICAROOT#/}/SPEEX.DLL
			${ICAROOT#/}/VDCAM.DLL
			${ICAROOT#/}/VORBIS.DLL
			${ICAROOT#/}/ADPCM.DLL
			${ICAROOT#/}/libproxy.so"
	fi
}
src_install() {
	dodir "${ICAROOT}"

	exeinto "${ICAROOT}"
	doexe *.DLL libctxssl.so libproxy.so wfica AuthManagerDaemon PrimaryAuthManager selfservice ServiceRecord

	exeinto "${ICAROOT}"/lib
	doexe lib/*.so

	if use nsplugin ; then
		exeinto "${ICAROOT}"
		doexe npica.so
		dosym "${ICAROOT}"/npica.so /usr/$(get_libdir)/nsbrowser/plugins/npica.so
	fi

	insinto "${ICAROOT}"
	doins nls/en/eula.txt

	insinto "${ICAROOT}"/config
	doins config/* config/.* nls/en/*.ini

	insinto "${ICAROOT}"/gtk
	doins gtk/*

	insinto "${ICAROOT}"/gtk/glade
	doins gtk/glade/*

	dodir "${ICAROOT}"/help

	insinto "${ICAROOT}"/config/usertemplate
	doins config/usertemplate/*

	LANGCODES="en"
	use linguas_de && LANGCODES+=" de"
	use linguas_es && LANGCODES+=" es"
	use linguas_fr && LANGCODES+=" fr"
	use linguas_ja && LANGCODES+=" ja"
	use linguas_zh_CN && LANGCODES+=" zh_CN"

	for lang in ${LANGCODES} ; do
		insinto "${ICAROOT}"/nls/${lang}
		doins nls/${lang}/*

		insinto "${ICAROOT}"/nls/$lang/UTF-8
		doins nls/${lang}.UTF-8/*

		insinto "${ICAROOT}"/nls/${lang}/LC_MESSAGES
		doins nls/${lang}/LC_MESSAGES/*

		insinto "${ICAROOT}"/nls/${lang}
		dosym UTF-8 "${ICAROOT}"/nls/${lang}/utf8
	done

	insinto "${ICAROOT}"/nls
	dosym en "${ICAROOT}"/nls/C

	insinto "${ICAROOT}"/icons
	doins icons/*

	insinto "${ICAROOT}"/keyboard
	doins keyboard/*

	rm -r "${S}"/keystore/cacerts || die
	dosym /etc/ssl/certs "${ICAROOT}"/keystore/cacerts

	# FIXME: Remove?
	#insinto "${ICAROOT}"/util
	#doins util/pac.js

	exeinto "${ICAROOT}"/util
	doexe util/{configmgr,conncenter,echo_cmd,gst_aud_play,gst_aud_read,gst_play,gst_read,hdxcheck.sh,icalicense.sh,libgstflatstm.so}
	doexe util/{lurdump,new_store,nslaunch,pnabrowse,sunraymac.sh,what,xcapture}

	doenvd "${FILESDIR}"/10ICAClient

	if use clip; then
		exeinto "/usr/bin"
		doexe "${FILESDIR}/wfica"
	else
		make_wrapper wfica "${ICAROOT}"/wfica . "${ICAROOT}"
	fi

	if use !clip; then
		dodir /etc/revdep-rebuild/
		echo "SEARCH_DIRS_MASK=\"${ICAROOT}\"" > "${D}"/etc/revdep-rebuild/70icaclient
	fi
	if use clip; then
		pax-mark "mL" "${D}${ICAROOT}/wfica"
		chmod +x "${D}/${ICAROOT}/"*.DLL
		chmod +x "${D}/${ICAROOT}/util/"*
		# No CPREFIX here
		mkdir -p "${D}/user_root/opt/Citrix" "${D}/user_root/etc"
		ln -s "/home/user/.ICAClient" "${D}/user_root/etc/icalicense"
		ln -s "${ICAROOT}" "${D}/user_root/opt/Citrix/ICAClient"
	fi

}

pkg_predeb() {
	doverictld2  "${ICAROOT}/wfica" e - - - c
}
