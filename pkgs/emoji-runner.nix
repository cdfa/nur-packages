{ fetchFromGitHub
, stdenv
, cmake
, krunner
, ydotool
, extra-cmake-modules
, ki18n
, kcmutils
}:

stdenv.mkDerivation rec {
  pname = "emoji-runner";
  version = "3.0.5";

  src = fetchFromGitHub {
    owner = "alex1701c";
    repo = "EmojiRunner";
    rev = "${version}";
    fetchSubmodules = true;
    hash = "sha256-Rt7Z0uEbzqRKxV1EpDr//RYaVr3D+Nj+7JS3EAO+hsM=";
  };

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    ki18n
    kcmutils
  ];

  buildInputs = [
    krunner
    ydotool
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_WITH_QT6=ON"
  ];
}
