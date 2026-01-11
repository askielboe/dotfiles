{ config, lib, pkgs, ... }:

{
  programs._1password-shell-plugins = {
    enable = true;
    # List of plugins to use from 1Password
    # Add plugins you want to integrate with 1Password
    plugins = with pkgs; [
      # Uncomment the plugins you use:
      # awscli2         # AWS CLI
      gh              # GitHub CLI (since you're using git)
      # glab           # GitLab CLI
      # stripe-cli     # Stripe CLI
      # azure-cli      # Azure CLI
      # doctl          # DigitalOcean CLI
      # flyctl         # Fly.io CLI
      # ngrok          # ngrok CLI
      # pulumi         # Pulumi CLI
      # terraform      # Terraform CLI
      # railway        # Railway CLI
      # turso          # Turso CLI
      # eas-cli        # Expo Application Services CLI
      # fastlane       # Fastlane CLI
      # cargo-edit     # Cargo edit CLI
      # wrangler       # Cloudflare Wrangler CLI
    ];
  };
}