#!/usr/bin/env bash

[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
EXE_NAME="brasfoot22-23.exe"
EXE_PATH="$BIN_DIR/$EXE_NAME"
EXTRACT_DIR="$BIN_DIR/extracted"
INNER_EXE_NAME="bf22-23.exe"
ROOT_DIR="$SCRIPT_DIR/../root"
CONTAINER_ROOT_DIR="$ROOT_DIR/root"
APP_DIR="$CONTAINER_ROOT_DIR/bin/brasfoot"
APPIMAGE_NAME="brasfoot.AppImage"
APPIMAGE_PATH="$CONTAINER_ROOT_DIR/bin/$APPIMAGE_NAME"
APPDIR_NAME="brasfoot.AppDir"
APPDIR_PATH="$BIN_DIR/$APPDIR_NAME"
JRE_STAGING_DIR="$BIN_DIR/jre"

mkdir -p "$BIN_DIR" "$EXTRACT_DIR" "$APP_DIR"

extract_with_docker_7z() {
	local input_file="$1"
	local output_dir="$2"

	docker run --rm \
		-v "$BIN_DIR:/work" \
		-w /work \
		alpine:3.20 \
		sh -lc 'apk add --no-cache p7zip >/dev/null && 7z x -y "$0" -o"$1" || true' \
		"$input_file" "$output_dir"
}

build_appimage() {
	local host_arch appimage_arch

	host_arch="$(uname -m)"
	case "$host_arch" in
		x86_64)
			appimage_arch="x86_64"
			;;
		aarch64|arm64)
			appimage_arch="aarch64"
			;;
		*)
			echo "Arquitetura nao suportada para appimagetool: $host_arch"
			exit 1
			;;
	esac

	rm -rf "$APPDIR_PATH" "$JRE_STAGING_DIR"
	mkdir -p "$APPDIR_PATH/usr/bin" \
		"$APPDIR_PATH/usr/share/applications" \
		"$APPDIR_PATH/usr/share/icons/hicolor/256x256/apps" \
		"$APPDIR_PATH/opt"

	cp -a "$APP_DIR" "$APPDIR_PATH/opt/brasfoot"

	docker run --rm \
		-v "$BIN_DIR:/work" \
		eclipse-temurin:8-jre-jammy \
		sh -lc 'rm -rf /work/jre && cp -r /opt/java/openjdk /work/jre'
	cp -a "$JRE_STAGING_DIR" "$APPDIR_PATH/opt/jre"

	cat >"$APPDIR_PATH/usr/bin/brasfoot" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APPDIR="$(cd "$(dirname "$0")/../.." && pwd)"
APP_HOME="$APPDIR/opt/brasfoot"
JAVA_BIN="$APPDIR/opt/jre/bin/java"
APP_EXE="$APP_HOME/bf22-23.exe"

mkdir -p "$HOME/.local/share/brasfoot"
cd "$APP_HOME"

exec "$JAVA_BIN" -Duser.home="$HOME/.local/share/brasfoot" -jar "$APP_EXE"
EOF
	chmod +x "$APPDIR_PATH/usr/bin/brasfoot"

	cat >"$APPDIR_PATH/AppRun" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APPDIR="$(cd "$(dirname "$0")" && pwd)"
exec "$APPDIR/usr/bin/brasfoot"
EOF
	chmod +x "$APPDIR_PATH/AppRun"

	cat >"$APPDIR_PATH/usr/share/applications/brasfoot.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Brasfoot
Comment=Brasfoot 2022-23
Exec=brasfoot
Icon=brasfoot
Categories=Game;SportsGame;
Terminal=false
EOF

	local icon_src
	icon_src="$(find "$APPDIR_PATH/opt/brasfoot" -type f -iname '*.png' | head -n 1 || true)"
	if [ -n "$icon_src" ]; then
		cp -f "$icon_src" "$APPDIR_PATH/usr/share/icons/hicolor/256x256/apps/brasfoot.png"
		cp -f "$APPDIR_PATH/usr/share/icons/hicolor/256x256/apps/brasfoot.png" "$APPDIR_PATH/brasfoot.png"
	else
		cat >"$APPDIR_PATH/brasfoot.xpm" <<'EOF'
/* XPM */
static char *brasfoot_xpm[] = {
"16 16 3 1",
"\t c None",
". c #1D6E3B",
"+ c #FFFFFF",
"................",
".....++++++.....",
"....++....++....",
"...++......++...",
"..++...++...++..",
"..++..++++..++..",
"..++...++...++..",
"...++......++...",
"....++....++....",
".....++++++.....",
"................",
"................",
"................",
"................",
"................",
"................"};
EOF
	fi

	cp -f "$APPDIR_PATH/usr/share/applications/brasfoot.desktop" "$APPDIR_PATH/brasfoot.desktop"

	docker run --rm \
		-v "$BIN_DIR:/work" \
		-w /work \
		ubuntu:24.04 \
		sh -lc 'apt-get update >/dev/null && apt-get install -y --no-install-recommends ca-certificates wget libglib2.0-0 file >/dev/null && (apt-get install -y --no-install-recommends libfuse2 >/dev/null || apt-get install -y --no-install-recommends libfuse2t64 >/dev/null) && wget -q -O appimagetool.AppImage "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-""$0"".AppImage" && chmod +x appimagetool.AppImage && ARCH="$0" APPIMAGE_EXTRACT_AND_RUN=1 ./appimagetool.AppImage "$1" "$2"' \
		"$appimage_arch" "$APPDIR_NAME" "$APPIMAGE_NAME"

	cp -f "$BIN_DIR/$APPIMAGE_NAME" "$APPIMAGE_PATH"
	chmod +x "$APPIMAGE_PATH"
}

cleanup_artifacts() {
	rm -rf "$APP_DIR"
	rm -rf "$ROOT_DIR/bin"
	rm -rf "$EXTRACT_DIR"
	rm -rf "$APPDIR_PATH"
	rm -rf "$JRE_STAGING_DIR"
	rm -f "$BIN_DIR/$EXE_NAME"
	rm -f "$BIN_DIR/$APPIMAGE_NAME"
	rm -f "$BIN_DIR/appimagetool.AppImage"
	rm -rf "$BIN_DIR/jar"
}

echo "[1/6] Baixando $EXE_NAME"
wget -O "$EXE_PATH" "https://www.brasfoot.com/download22/$EXE_NAME"

echo "[2/6] Limpando pasta de extração"
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"

echo "[3/6] Extraindo $EXE_NAME com docker run + 7z"
extract_with_docker_7z "$EXE_NAME" "extracted"

if [ -f "$EXTRACT_DIR/$INNER_EXE_NAME" ]; then
	echo "Arquivo principal encontrado: $EXTRACT_DIR/$INNER_EXE_NAME"
else
	echo "Aviso: $INNER_EXE_NAME nao encontrado na extração"
fi

echo "[4/6] Copiando conteúdo extraído para $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
cp -a "$EXTRACT_DIR/." "$APP_DIR/"

echo "[5/6] Gerando $APPIMAGE_PATH"
build_appimage

echo "[6/6] Limpando artefatos intermediarios"
cleanup_artifacts

echo "Concluido. AppImage pronto em: $APPIMAGE_PATH"

