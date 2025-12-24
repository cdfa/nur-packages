{ stdenv
, lib
, callPackage
, path
, breakpointHook # todo: remove
, stdenvNoCC
, fetchurl
, nixosTests
, srcOnly
, libpulseaudio
, flac
, libxml2
, libxslt
, # sourceExecutableName is the name of the binary in the source package
  sourceExecutableName ? "code-oss"
, commandLineArgs ? ""
}:

(callPackage (toString path + "/pkgs/applications/editors/vscode/generic.nix") rec {
  version = "1.96.2";
  pname = "vscode-oss";

  # This is used for VS Code - Remote SSH test
  rev = "fabdb6a30b49f79a7aba0f2ad9df9b399473380f";

  executableName = "code-oss";
  longName = "Visual Studio Code";
  shortName = "Code - OSS";
  inherit commandLineArgs sourceExecutableName;
  useVSCodeRipgrep = true;

  src = callPackage ./vscode-oss-src.nix { };

  sourceRoot = "";
  updateScript = null; # todo

  # As tests run without networking, we need to download this for the Remote SSH server
  vscodeServer = srcOnly {
    name = "vscode-server-${rev}.tar.gz";
    src = fetchurl {
      name = "vscode-server-${rev}.tar.gz";
      url = "https://update.code.visualstudio.com/commit:${rev}/server-linux-x64/stable";
      sha256 = "0rjd4f54k58k97gxvnivwj52aha5s8prws1izvmg43vphhfvk014";
    };
    stdenv = stdenvNoCC;
  };

  tests = { inherit (nixosTests) vscode-remote-ssh; };

  # hasVsceSign = true;

  meta = with lib; {
    description = ''
      Open source source code editor developed by Microsoft for Windows,
      Linux and macOS
    '';
    mainProgram = "code-oss";
    longDescription = ''
      Open source source code editor developed by Microsoft for Windows,
      Linux and macOS. It includes support for debugging, embedded Git
      control, syntax highlighting, intelligent code completion, snippets,
      and code refactoring. It is also customizable, so users can change the
      editor's theme, keyboard shortcuts, and preferences
    '';
    homepage = "https://code.visualstudio.com/";
    downloadPage = "https://code.visualstudio.com/Updates";
    license = licenses.unfree;
    maintainers = with maintainers; [
      eadwu
      synthetica
      bobby285271
      johnrtitor
      jefflabonte
    ];
    # No darwin because because VS Code is notarized.
    # See https://eclecticlight.co/2022/06/17/app-security-changes-coming-in-ventura/ for more information.
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}).overrideAttrs (final: prev:
builtins.removeAttrs prev [ "updateScript" ] // {
  dontUnpack = true;
  buildInputs = prev.buildInputs ++ [
    breakpointHook
    libpulseaudio
    flac
    libxml2
    libxslt
  ];

  prePatch = ''
    mkdir -p resources/app
    touch resources/app/node_modules.asar
    cp -r --update=none $src/* . # don't overwrite resources/app/node_modules.asar
    rm resources/app/node_modules.asar
    cp --no-preserve=mode,ownership $src/resources/app/node_modules.asar ./resources/app/node_modules.asar
  '';
})
