# /lib/rcscripts/addons/raid-start.sh:  Setup raid volumes at boot
# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/mdadm/files/raid-start.sh,v 1.5 2006/11/10 00:27:07 vapier Exp $

[[ -f /proc/mdstat ]] || exit 0

# We could make this dynamic, but eh
#[[ -z ${MAJOR} ]] && export MAJOR=$(awk '$2 == "md" { print $1 }' /proc/devices)
MAJOR=9

# Try to make sure the devices exist before we use them
create_devs() {
	local node dir minor
	for node in $@ ; do
		[[ ${node} != /dev/* ]] && node=/dev/${node}
		[[ -e ${node} ]] && continue

		dir=${node%/*}
		[[ ! -d ${dir} ]] && mkdir -p "${dir}"

		minor=${node##*/}
		mknod "${node}" b ${MAJOR} ${minor##*md} &> /dev/null
	done
}

# Start software raid with raidtools (old school)
if [[ -x /sbin/raidstart && -f /etc/raidtab ]] ; then
	devs=$(awk '/^[[:space:]]*raiddev/ { print $2 }' /etc/raidtab)
	if [[ -n ${devs} ]] ; then
		create_devs ${devs}
		ebegin "Starting up RAID devices (raidtools)"
		output=$(raidstart -aq 2>&1)
		ret=$?
		[[ ${ret} -ne 0 ]] && echo "${output}"
		eend ${ret}
	fi
fi

# Start software raid with mdadm (new school)
mdadm_conf="/etc/mdadm/mdadm.conf"
[[ -e /etc/mdadm.conf ]] && mdadm_conf="/etc/mdadm.conf"
if [[ -x /sbin/mdadm && -f ${mdadm_conf} ]] ; then
	devs=$(awk '/^[[:space:]]*ARRAY/ { print $2 }' ${mdadm_conf})
	if [[ -n ${devs} ]] ; then
		create_devs ${devs}
		ebegin "Starting up RAID devices (mdadm)"
		output=$(mdadm -As 2>&1)
		ret=$?
		[[ ${ret} -ne 0 ]] && echo "${output}"
		eend ${ret}
	fi
fi

# vim:ts=4
