#!/bin/bash

is_encrypted () {
	grep -q "ENCRYPTED" "$1"
}

get_password () {
	local pw="$(egrep "\b${1}\b" ipsec.secrets | tr -s ' ' | cut -d' ' -f4)"
	pw="${pw#\"}"
	pw="${pw%\"}"
	echo "$pw"
}

decrypt_key () {
	local key="$1"
	local pw="$2"
	if echo "$pw" | openssl rsa -in "$k" -passin stdin -out "$k".dec 2>/dev/null; then
		# cat into original file instead of mv to keep permissions
		cat "$k".dec > "$k"
		rm "$k".dec
	else
		echo "Failed to decrypt encrypted key $k (wrong password in ipsec.secrets)"
	fi
}

pushd /etc/admin/ike2/cert
for k in *.key; do
	if is_encrypted "$k"; then
		pw="$(get_password "$k")"
		decrypt_key "$k" "$pw"
	fi
done
popd
