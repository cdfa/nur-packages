{ buildFishPlugin, fetchFromGitHub, lib }:

buildFishPlugin rec {
  pname = "replay-fish";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "jorgebucaran";
    repo = "replay.fish";
    rev = "${version}";
    hash = "sha256-bM6+oAd/HXaVgpJMut8bwqO54Le33hwO9qet9paK1kY=";
  };

  meta = with lib; {
    description = "Run Bash commands, replay changes in Fish 🍤";
    homepage = "https://github.com/jorgebucaran/replay.fish";
    license = licenses.mit;
    maintainers = [ "cdfa" ];
  };
}
