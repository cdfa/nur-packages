{ stdenv
, lib
, buildNpmPackage
, callPackage
, fetchFromGitHub
, pkg-config
, libnotify
, libX11
, libsecret
, libxkbfile
, krb5
, nss
, alsa-lib
, playwright-driver
, ripgrep
, breakpointHook # todo: remove
, electron_32
, fetchNpmDeps
, nodejs
, git
, zip
}:

buildNpmPackage rec {
  pname = "vscode-oss";
  version = "1.96.2";

  # src = fetchFromGitHub {
  #   owner = "microsoft";
  #   repo = "vscode";
  #   rev = "${version}";
  #   hash = "sha256-hWGzl1cbFfdNVNpJpJxHIFRdjqvcZ218QG/MiZd3Oy4=";
  # };
  # src = /nix/store/7jcazamncq9vlrlh8xhxyazwiklk7b0f-vscode-oss-1.96.2;
  src = /nix/store/5qfrnmz9xb6gz3p3g9ck6m3424llnh2r-vscode-oss-1.96.2;
  dontUnpack = true;
  prePatch = ''
    cp -r --no-preserve=mode,ownership $src source
    src=./source
    cd $src
    patch -R build/gulpfile.vscode.js < ${./noPackage.patch}
  '';
  # npmConfigHook = "";

  buildInputs = [
    libnotify
    libX11
    libsecret
    libxkbfile
    krb5
    nss
    alsa-lib
    breakpointHook
    electron_32
  ];

  nativeBuildInputs = [
    pkg-config
    ripgrep
    git
  ];

  nodeArch =
    if stdenv.hostPlatform.isAarch64 then
      "arm64"
    else if stdenv.hostPlatform.isx86_64 then
      "x64"
    else
      throw ("Unsupported architecture: " + stdenv.hostPlatform.system);

  nodePlatform =
    if stdenv.hostPlatform.isLinux then
      "linux"
    else if stdenv.hostPlatform.isDarwin then
      "darwin"
    else
      throw ("Unsupported OS: " + stdenv.hostPlatform.system);

  forceGitDeps = true;
  forceEmptyCache = true;
  npmInstallFlags = "--cpu=${nodeArch}";
  npmDeps =
    (fetchNpmDeps {
      inherit src forceGitDeps forceEmptyCache;
      name = "${pname}-${version}-npm-deps";
      # hash = "sha256-HWFvoxCEMo7rX5ukkMoZZEcCuJFvhXVxgGaclVm/nl0=";
      hash = "sha256-LGcuAj55oGKwzoRAj3RMTGXdRHmgV8fC3V3ktv170d0=";
    }).overrideAttrs {
      buildPhase = ''
        runHook preBuild

        local dirs=$(${nodejs}/bin/node -e 'require("./build/npm/dirs").dirs.forEach(dir => console.log(dir))')

        prefetch-npm-deps package-lock.json $out

        while IFS= read -r dir; do
          if [[ -n $dir ]]; then
            echo "Fetching npm deps for $dir"
            prefetch-npm-deps $dir/package-lock.json $out/$dir
          fi
        done <<< $dirs

        runHook postBuild
      '';
    };

  PLAYWRIGHT_BROWSERS_PATH = "${playwright-driver.browsers}";
  PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = true;
  PLAYWRIGHT_SKIP_BROWSER_GC = 1;
  PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = true;

  makeCacheWritable = true;

  ripgrepVersion = "v13.0.0-10";
  ripgrep_archive_name =
    with stdenv.hostPlatform;
    if isDarwin then
      if isAarch64 then
        "aarch64-apple-darwin"
      else
        "x86_64-apple-darwin"
    else if isLinux then
      if isx86_64 then
        "x86_64-unknown-linux-musl"
      else if isAarch64 then
        "aarch64-unknown-linux-musl"
      else
        "i686-unknown-linux-musl"
    else
      throw "Could not determine ripgrep archive name";

  patches = [ ./packageOnly.patch ];
  preBuild = ''
    patch build/lib/electron.js < ${./disableChecksums.patch}
    # patch node_modules/@vscode/gulp-electron/src/download.js < ${./debug.patch}
    # patch -R node_modules/@vscode/gulp-electron/src/download.js < ${./debug2.patch}
    # patch -R node_modules/@vscode/gulp-electron/src/index.js < ${./debug3.patch}
    # patch -R node_modules/got/dist/source/core/index.js < ${./debug4.patch}
  '';

  electronHash = builtins.hashString "sha256" "https://github.com/electron/electron/releases/download/${electronVersion}";
  electronVersion = "v32.2.6";
  electronPlatform = "linux"; # todo
  electronArch = "x64";
  DEBUG = "*";
  postPatch = [
    ''
      echo "copying ripgrep to cache"
      node_ripgrep_version=$(node -p -e "require(\"./package-lock.json\").packages['node_modules/@vscode/ripgrep'].version")
      mkdir -p $TMPDIR/vscode-ripgrep-cache-$node_ripgrep_version
      tar -czf $TMPDIR/vscode-ripgrep-cache-$node_ripgrep_version/ripgrep-${ripgrepVersion}-${ripgrep_archive_name}.tar.gz -C ${ripgrep}/bin rg
    ''
    ''
      echo "Adding electron to electron download cache"
      local electronCacheDir=$TMPDIR/.cache/electron/${electronHash}
      mkdir -p $electronCacheDir
      cp -r ${electron_32}/libexec/electron $electronCacheDir/source
      pushd $electronCacheDir/source
      chmod u+w locales
      chmod u+w resources
      ${zip}/bin/zip -r $electronCacheDir/electron-${electronVersion}-${electronPlatform}-${electronArch}.zip ./*
      popd
    ''
    ''
      # Run config hook for all sub packages
      local npmDepsRoot=$npmDeps
      local dirs=$(${nodejs}/bin/node -e 'require("./build/npm/dirs").dirs.forEach(dir => console.log(dir))')
      while IFS= read -r dir; do
        if [[ -n $dir ]]; then
          echo "Running npmConfigHook for $dir"
          npmDeps=$npmDepsRoot/$dir
          npmRoot=$dir
          npmConfigHook
          rm -r $TMPDIR/cache
        fi
      done <<< $dirs

      npmDeps=$npmDepsRoot
      unset npmRoot
    ''
    ''
      # Work around build/npm/postinstall.js doing `git config ...`
      git init
    ''
    ''
      cp --update=all ${./product.json} product.json
    ''
    ''
      # Add completions for code-oss
      cp "resources/completions/bash/code" "resources/completions/bash/code-oss"
      cp "resources/completions/zsh/_code" "resources/completions/zsh/_code-oss"
    ''
    ''
      # Patch completions with correct names
      sed -i 's|@@APPNAME@@|code-oss|g' "resources/completions/"{bash/code-oss,zsh/_code-oss}
    ''
  ];

  npmBuildScript = "gulp";
  npmBuildFlags = "-- vscode-${nodePlatform}-${nodeArch}-min";

  # patches = [./noPackage.patch];
  npmInstallHook = "";
  installPhase = ''
    cp -r "." "$out"
  '';

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
    license = licenses.unfree;
    maintainers = [ "cdfa" ]; # todo
    platforms = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
      "aarch64-linux"
    ];
  };
}
