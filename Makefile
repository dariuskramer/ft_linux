BOX_TEMPLATE=box/template.json
BOX_FILE=lfs-archlinux-libvirt.box
BOX_NAME=lfs/archlinux
PKG_CACHE_DIR=box/pkg-cache
WGET_OPTS=--directory-prefix=${PKG_CACHE_DIR} --no-verbose -N

all: box
	vagrant up

${BOX_FILE}:
	@mkdir -p box/{http,provision,pkg-cache}
	cd box && ./import-scripts.sh
	packer build ${BOX_TEMPLATE}
	vagrant box add --force --name ${BOX_NAME} ${BOX_FILE}

box: ${BOX_FILE}

pkg-cache:
	wget ${WGET_OPTS} 'http://www.linuxfromscratch.org/lfs/view/stable-systemd/wget-list'
	wget ${WGET_OPTS} 'http://www.linuxfromscratch.org/lfs/view/stable-systemd/md5sums'
	wget ${WGET_OPTS} --input-file=${PKG_CACHE_DIR}/wget-list --continue
	cd ${PKG_CACHE_DIR} && md5sum -c md5sums

clean:
	vagrant destroy -f

fclean: clean
	${RM} -f ${BOX_FILE}

.PHONY: pkg-cache clean fclean
