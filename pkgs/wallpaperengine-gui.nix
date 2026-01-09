{ fetchFromGitHub
, stdenv
, cmake
, pkg-config
, qt6
}:

stdenv.mkDerivation {
  pname = "wallpaperengine-gui";
  version = "1.1.6";

  src = fetchFromGitHub {
    owner = "MikiDevLog";
    repo = "wallpaperengine-gui";
    rev = "v1.1.6";
    fetchSubmodules = true;
    hash = "sha256-A2+8zKHns1UKQ5r0XXp0AaNAB+eAnEe8GfKpiARrqVY=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtwebengine
    qt6.qtmultimedia
  ];
}
