{ pkgs, ... }:

let
  fasttext-model = pkgs.fetchurl {
    url = "https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.176.bin";
    sha256 = "0kkncb1swi2azh0ci7kq0sfg1mw559wy8jafhk3iq9mwa5afqsby";
  };

  server-properties = pkgs.writeText "server.properties" ''
    fasttextModel=${fasttext-model}
    fasttextBinary=${pkgs.fasttext}/bin/fasttext
  '';
in
{
  home.file.".config/languagetool/server.properties".source = server-properties;

  launchd.agents.languagetool = {
    enable = true;
    config = {
      Label = "com.user.languagetool";
      ProgramArguments = [
        "${pkgs.jre}/bin/java"
        "-cp"
        "${pkgs.languagetool}/share/languagetool-server.jar"
        "org.languagetool.server.HTTPServer"
        "--config"
        "/Users/askielboe/.config/languagetool/server.properties"
        "--port"
        "8081"
        "--allow-origin"
        "*"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/askielboe/Library/Logs/languagetool.log";
      StandardErrorPath = "/Users/askielboe/Library/Logs/languagetool.err.log";
    };
  };
}