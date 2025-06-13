#!/bin/sh

APP=chromium

# TEMPORARY DIRECTORY
mkdir -p tmp
cd ./tmp || exit 1

# DOWNLOAD APPIMAGETOOL
if ! test -f ./appimagetool; then
	wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-aarch64.AppImage -O appimagetool
	chmod a+x ./appimagetool
fi

# CREATE CHROMIUM BROWSER APPIMAGES

_create_chromium_appimage() {
	# DOWNLOAD THE SNAP PACKAGE
	if ! test -f ./*.snap; then
		if wget --version | head -1 | grep -q ' 1.'; then
			wget -q --no-verbose --show-progress --progress=bar "$(curl -H 'Snap-Device-Series: 16' http://api.snapcraft.io/v2/snaps/info/chromium --silent | sed 's/\[{/\n/g; s/},{/\n/g' | grep -i "$CHANNEL" | grep arm64  | head -1 | sed 's/[()",{} ]/\n/g' | grep "^http")"
		else
			wget "$(curl -H 'Snap-Device-Series: 16' http://api.snapcraft.io/v2/snaps/info/chromium --silent | sed 's/\[{/\n/g; s/},{/\n/g' | grep -i "$CHANNEL" | grep arm64  | head -1 | sed 's/[()",{} ]/\n/g' | grep "^http")"
		fi
	fi

	# EXTRACT THE SNAP PACKAGE AND CREATE THE APPIMAGE
	unsquashfs -f ./*.snap
	mkdir -p "$APP".AppDir
	VERSION=$(cat ./squashfs-root/snap/*.yaml | grep "^version" | head -1 | cut -c 10-)

	mv ./squashfs-root/usr/lib/chromium*/* ./"$APP".AppDir/
	mv ./squashfs-root/*.png ./"$APP".AppDir/
	mv ./squashfs-root/bin/*"$APP"*.desktop ./"$APP".AppDir/
	if test -d ./squashfs-root/etc; then cp -r ./squashfs-root/etc ./"$APP".AppDir/; fi
	if test -d ./squashfs-root/lib; then cp -r ./squashfs-root/lib* ./"$APP".AppDir/; fi
	if test -d ./squashfs-root/usr; then cp -r ./squashfs-root/usr ./"$APP".AppDir/; fi

	sed -i 's#/chromium.png#chromium#g' ./"$APP".AppDir/*.desktop

	cat <<-'HEREDOC' >> ./"$APP".AppDir/AppRun
	#!/bin/sh
	HERE="$(dirname "$(readlink -f "${0}")")"
	export UNION_PRELOAD="${HERE}"
	exec ${HERE}/chrome "$@"
	HEREDOC
	chmod a+x ./"$APP".AppDir/AppRun

	export UNION_PRELOAD=/:"${HERE}"
	export LD_LIBRARY_PATH="${HERE}"/usr/lib/:"${HERE}"/usr/lib/i386-linux-gnu/:"${HERE}"/usr/lib/x86_64-linux-gnu/:"${HERE}"/usr/lib/aarch64-linux-gnu/:"${HERE}"/lib/:"${HERE}"/lib/i386-linux-gnu/:"${HERE}"/lib/x86_64-linux-gnu/:"${HERE}"/lib/aarch64-linux-gnu/:"${LD_LIBRARY_PATH}"
	export PATH="${HERE}"/usr/bin/:"${HERE}"/usr/sbin/:"${HERE}"/usr/games/:"${HERE}"/bin/:"${HERE}"/sbin/:"${PATH}"
	export PYTHONPATH="${HERE}"/usr/share/pyshared/:"${HERE}"/usr/lib/python*/:"${PYTHONPATH}"
	export PYTHONHOME="${HERE}"/usr/:"${HERE}"/usr/lib/python*/
	export XDG_DATA_DIRS="${HERE}"/usr/share/:"${XDG_DATA_DIRS}"
	export PERLLIB="${HERE}"/usr/share/perl5/:"${HERE}"/usr/lib/perl5/:"${PERLLIB}"
	export GSETTINGS_SCHEMA_DIR="${HERE}"/usr/share/glib-2.0/schemas/:"${GSETTINGS_SCHEMA_DIR}"
	export QT_PLUGIN_PATH="${HERE}"/usr/lib/qt4/plugins/:"${HERE}"/usr/lib/i386-linux-gnu/qt4/plugins/:"${HERE}"/usr/lib/x86_64-linux-gnu/qt4/plugins/:"${HERE}"/usr/lib/aarch-linux-gnu/qt4/plugins/:"${HERE}"/usr/lib32/qt4/plugins/:"${HERE}"/usr/lib64/qt4/plugins/:"${HERE}"/usr/lib/qt5/plugins/:"${HERE}"/usr/lib/i386-linux-gnu/qt5/plugins/:"${HERE}"/usr/lib/x86_64-linux-gnu/qt5/plugins/:"${HERE}"/usr/lib/aarch-linux-gnu/qt5/plugins/:"${HERE}"/usr/lib32/qt5/plugins/:"${HERE}"/usr/lib64/qt5/plugins/:"${QT_PLUGIN_PATH}"

	ARCH=aarch64 ./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
	-u "gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|Chromium-Web-Browser-appimage|continuous|*-$CHANNEL-*aarch64.AppImage.zsync" \
	./"$APP".AppDir Chromium-"$CHANNEL"-"$VERSION"-aarch64.AppImage || exit 1
}

CHANNEL="stable"
mkdir -p "$CHANNEL" && cp ./appimagetool ./"$CHANNEL"/appimagetool && cd "$CHANNEL" || exit 1
_create_chromium_appimage
cd ..
mv ./"$CHANNEL"/*.AppImage* ./

CHANNEL="candidate"
mkdir -p "$CHANNEL" && cp ./appimagetool ./"$CHANNEL"/appimagetool && cd "$CHANNEL" || exit 1
_create_chromium_appimage
cd ..
mv ./"$CHANNEL"/*.AppImage* ./

CHANNEL="beta"
mkdir -p "$CHANNEL" && cp ./appimagetool ./"$CHANNEL"/appimagetool && cd "$CHANNEL" || exit 1
_create_chromium_appimage
cd ..
mv ./"$CHANNEL"/*.AppImage* ./

CHANNEL="edge"
mkdir -p "$CHANNEL" && cp ./appimagetool ./"$CHANNEL"/appimagetool && cd "$CHANNEL" || exit 1
_create_chromium_appimage
cd ..
mv ./"$CHANNEL"/*.AppImage* ./

cd ..
mv ./tmp/*.AppImage* ./
