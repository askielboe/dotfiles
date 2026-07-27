{ pkgs, ... }:
let
  # One-time interactive OAuth login for the Google Chat unread menu-bar item
  # (SwiftBar; see modules/home-manager/dotfiles/swiftbar/gchat.1m.py, which polls
  # via the neutral dotfiles/gchat/gchat.py library). Run `gchat-login <label>`
  # once per account; it runs Google's loopback OAuth flow and writes a refresh
  # token to ~/.local/state/gchat/<label>.json, which the poller refreshes in
  # place (rotating, so kept out of the read-only nix store). Stdlib-only Python,
  # so the wrapper just puts python3 on PATH and execs the script from the store.
  #
  # GOOGLE CLOUD SETUP (once, both accounts are Workspace so this is the easy
  # path — Internal consent, non-expiring refresh tokens):
  #   1. console.cloud.google.com -> create/pick a project.
  #   2. APIs & Services -> Library -> enable "Google Chat API".
  #   3. APIs & Services -> OAuth consent screen -> User type "Internal".
  #   4. Add scopes: chat.spaces.readonly, chat.messages.readonly,
  #      chat.users.readstate.readonly (all read-only), plus openid + email
  #      (non-sensitive; lets gchat-login record which account each token is, so
  #      the menu-bar item can deep-link to that account via ?authuser=<email>).
  #   5. Credentials -> Create credentials -> OAuth client ID -> "Desktop app".
  #      Note the client ID and secret.
  #   6. After `hs`, run once per account (paste the id/secret when prompted, or
  #      export GCHAT_CLIENT_ID / GCHAT_CLIENT_SECRET first):
  #         gchat-login work-a
  #         gchat-login work-b
  gchat-login = pkgs.writeShellApplication {
    name = "gchat-login";
    runtimeInputs = [ pkgs.python3 ];
    text = ''exec python3 ${./gchat-login.py} "$@"'';
  };
in
{
  # One-time OAuth login CLI: `gchat-login <label>` mints a Google Chat token per
  # account for the menu-bar unread item.
  environment.systemPackages = [ gchat-login ];
}
