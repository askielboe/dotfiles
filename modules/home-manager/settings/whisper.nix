{ pkgs, ... }:

let
  whisperLargeV3TurboQ5Model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin";
    hash = "sha256-OUIhcJzVrR9AxG5gMcphvOiJMebgiMGIKUxtWlX/p+I=";
  };
  whisperLargeV2Q5Model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v2-q5_0.bin";
    hash = "sha256-OiFINyIeRTDbwf6Nc08wKvOT6zC9DtBGBC6/S69w9vI=";
  };
  whisperLargeV3Q5Model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-q5_0.bin";
    hash = "sha256-11eV7P8/g7X6qJ0ZAGBK2MeAq9Vzn65AbeGfI+zZitE=";
  };
  whisperMediumQ5Model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium-q5_0.bin";
    hash = "sha256-Gf6ks4DDphjsRyPD7vLreF/7oNBTjPQ/jyNeezs0Ig8=";
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
    whisper = "whisper-cli -m $WHISPER_CPP_MODELS/ggml-large-v3-turbo-q5_0.bin";
  };

  home.file.".cache/huggingface/whisper-cpp-models/ggml-large-v3-turbo-q5_0.bin".source =
    whisperLargeV3TurboQ5Model;
  home.file.".cache/huggingface/whisper-cpp-models/ggml-large-v2-q5_0.bin".source =
    whisperLargeV2Q5Model;
  home.file.".cache/huggingface/whisper-cpp-models/ggml-large-v3-q5_0.bin".source =
    whisperLargeV3Q5Model;
  home.file.".cache/huggingface/whisper-cpp-models/ggml-medium-q5_0.bin".source =
    whisperMediumQ5Model;
}
