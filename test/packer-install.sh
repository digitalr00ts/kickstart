#/bin/sh

PACKER_VER="${PACKER_VER:-1.0.3}"

install_packer () {
	OS="$(uname -s)"

	case "$OS" in
		'Linux')
			PACKER_ZIP="packer_${PACKER_VER}_linux_amd64.zip" ;;
		'Darwin')
			PACKER_ZIP="packer_${PACKER_VER}_darwin_amd64.zip" ;;
		*)
			echo 'Unsupported OS';exit 1 ;;
	esac

	curl -sSLO https://releases.hashicorp.com/packer/${PACKER_VER}/${PACKER_ZIP}
	unzip -qox "${PACKER_ZIP}"
	rm -f "${PACKER_ZIP}"
}

[ -f ./packer ] && [ "$(./packer --version)" == "$PACKER_VER" ] || install_packer
