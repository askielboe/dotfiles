{ ... }: {
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;

    casks = [
      "spotify"
    ];
  };
}
