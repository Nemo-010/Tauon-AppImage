#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DEPLOY_PYTHON=1
export DEPLOY_PIPEWIRE=1
export USE_HOST_DRIVERS_EXPERIMENTAL=1
export DEPLOY_SDL=1

# fix bug making the app assume that it can write to its site-package dir
find /usr/lib/python*/site-packages \
	-type f -name '*.py' -exec sed -i -e 's|/snap/|/|g' {} \;

# v13.1.0 ships a native `tauon` launcher that handles the playback commands
# itself, so the wrapper in AppDir/bin is only needed for older releases that
# installed `tauonmb` instead. A wrapper here would shadow the real binary.
if [ -f /usr/bin/tauonmb ]; then
	MAIN_BIN=tauonmb
elif [ -f /usr/bin/tauon ]; then
	MAIN_BIN=tauon
	rm -f ./AppDir/bin/tauon
fi
export MAIN_BIN

# Deploy dependencies
quick-sharun \
	"/usr/bin/$MAIN_BIN"        \
	/usr/bin/ffmpeg               \
	/usr/lib/libgtk-3.so*         \
	/usr/lib/libssl.so*           \
	/usr/lib/libgme.so*           \
	/usr/lib/libwavpack.so*       \
	/usr/lib/libnotify.so*        \
	/usr/lib/libopenmpt.so*       \
	/usr/lib/libvorbisfile.so*    \
	/usr/lib/libopusfile.so*      \
	/usr/lib/libsamplerate.so*    \
	/usr/lib/libimagequant.so*    \
	/usr/lib/libopenjp2.so*		  
		  

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --test ./dist/*.AppImage
