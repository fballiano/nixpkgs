{ mkDerivation, lib, stdenv, fetchFromGitHub, pkg-config
, boost, libtorrent-rasterbar, qtbase, qttools, qtsvg
, debugSupport ? false
, guiSupport ? true, dbus ? null # GUI (disable to run headless)
, webuiSupport ? true # WebUI
, trackerSearch ? true, python3 ? null
}:

assert guiSupport -> (dbus != null);
assert trackerSearch -> (python3 != null);

with lib;
mkDerivation rec {
  pname = "qbittorrent";
  version = "4.4.5";

  src = fetchFromGitHub {
    owner = "qbittorrent";
    repo = "qBittorrent";
    rev = "release-${version}";
    sha256 = "sha256-EgRDNOJ4szdZA5ipOuGy2R0oVdjWcuqPU3ecU3ZNK3g=";
  };

  enableParallelBuilding = true;

  # NOTE: 2018-05-31: CMake is working but it is not officially supported
  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ boost libtorrent-rasterbar qtbase qttools qtsvg ]
    ++ optional guiSupport dbus # D(esktop)-Bus depends on GUI support
    ++ optional trackerSearch python3;

  # Otherwise qm_gen.pri assumes lrelease-qt5, which does not exist.
  QMAKE_LRELEASE = "lrelease";

  configureFlags = [
    "--with-boost-libdir=${boost.out}/lib"
    "--with-boost=${boost.dev}" ]
    ++ optionals (!guiSupport) [ "--disable-gui" "--enable-systemd" ] # Also place qbittorrent-nox systemd service files
    ++ optional (!webuiSupport) "--disable-webui"
    ++ optional debugSupport "--enable-debug";

  qtWrapperArgs = optional trackerSearch "--prefix PATH : ${makeBinPath [ python3 ]}";

  postInstall = lib.optionalString stdenv.isDarwin ''
    mkdir -p $out/{Applications,bin}
    cp -R src/qbittorrent.app $out/Applications
    makeWrapper $out/{Applications/qbittorrent.app/Contents/MacOS,bin}/qbittorrent
  '';

  meta = {
    description = "Featureful free software BitTorrent client";
    homepage    = "https://www.qbittorrent.org/";
    changelog   = "https://github.com/qbittorrent/qBittorrent/blob/release-${version}/Changelog";
    license     = licenses.gpl2Plus;
    platforms   = platforms.unix;
    maintainers = with maintainers; [ Anton-Latukha ];
  };
}
