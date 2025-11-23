{ pkgs, ... }:

let
  whisperLargeV3Q5Model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-q5_0.bin";
    hash = "sha256-11eV7P8/g7X6qJ0ZAGBK2MeAq9Vzn65AbeGfI+zZitE=";
  };
in
{
  home.packages = with pkgs; [
    whisper-cpp
  ];

  home.sessionVariables = {
    HF_HOME = "$HOME/.cache/huggingface";
    WHISPER_CPP_MODELS = "$HF_HOME/whisper-cpp-models";
  };

  home.shellAliases = {
    whisper = "whisper-cli -m $WHISPER_CPP_MODELS/ggml-large-v3-q5_0.bin";
  };

  home.file.".cache/huggingface/whisper-cpp-models/ggml-large-v3-q5_0.bin".source =
    whisperLargeV3Q5Model;
}
