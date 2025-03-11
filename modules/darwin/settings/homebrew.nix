{ ... }: {
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;

    casks = [
      "jordanbaird-ice" # Hide menu bar icons
      "spotify"
    ];
  };
}
