BOX_TEMPLATE=box/template.json
BOX_FILE=lfs-archlinux-libvirt.box
BOX_NAME=lfs/archlinux

${BOX_FILE}:
	@mkdir -p box/{http,provision,pkg-cache}
	cd box && ./import-scripts.sh
	packer build ${BOX_TEMPLATE}
	vagrant box add --force --name ${BOX_NAME} ${BOX_FILE}

box: ${BOX_FILE}
