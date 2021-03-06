#!/bin/bash

trap '{ echo -e "error ${?}\nthe command executing at the time of the error was\n${BASH_COMMAND}\non line ${BASH_LINENO[0]}" && tail -n 10 ${INSTALL_LOG} && exit $? }' ERR

export DEBIAN_FRONTEND="noninteractive"
export PACKAGES=(
	'curl'
	'libidn11'
	'liblua5.1-expat0'
	'libssl1.0.0'
	'lua-bitop'
	'lua-dbi-mysql'
	'lua-dbi-postgresql'
	'lua-dbi-sqlite3'
	'lua-event'
	'lua-expat'
	'lua-filesystem'
	'lua-sec'
	'lua-socket'
	'lua-zlib'
	'lua5.1'
	'openssl'
	'ca-certificates'
)

pre_install() {
	apt-get update
	apt-get install -yq ${PACKAGES[@]}

	echo "deb http://packages.prosody.im/debian jessie main" > /etc/apt/sources.list.d/prosody.list || return 1
	curl --location https://prosody.im/files/prosody-debian-packages.key | apt-key add - || return 1

	mkdir -p /data/prosody-modules /data/certs /data/conf.d

	apt-get update 2>&1 || return 1

    	return 0
}

install() {
	apt-get install -yq prosody || return 1

	curl --location https://hg.prosody.im/prosody-modules/archive/tip.tar.gz | tar xz -C /data/prosody-modules --strip-components=1 || return 1

	return 0
}

post_install() {
	apt-get autoremove 2>&1 || return 1
	apt-get autoclean 2>&1 || return 1
	rm -fr /var/lib/apt 2>&1 || return 1

	chmod +x /usr/local/bin/* || return 1

	return 0
}

build() {
	if [ ! -f "${INSTALL_LOG}" ]
	then
		touch "${INSTALL_LOG}" || exit 1
	fi

	tasks=(
        'pre_install'
	'install'
	)

	for task in ${tasks[@]}
	do
		echo "Running build task ${task}..." || exit 1
		${task} | tee -a "${INSTALL_LOG}" || exit 1
	done
}

if [ $# -eq 0 ]
then
	echo "No parameters given! (${@})"
	echo "Available functions:"
	echo

	compgen -A function

	exit 1
else
	for task in ${@}
	do
		echo "Running ${task}..." 2>&1  || exit 1
		${task} || exit 1
	done
fi
