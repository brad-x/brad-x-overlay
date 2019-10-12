USE="-systemd build" emerge libcap-ng util-linux --nodeps -1av
USE="-gpm" emerge ncurses -1av
USE="-tiff -webp" emerge media-libs/tiff media-libs/libwebp --nodeps -1av
USE="-qt5 -cryptsetup -filecaps" emerge system -uDNav
