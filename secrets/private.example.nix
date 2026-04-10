{
  user = {
    name = "Your Name";
    email = "your.email@example.com";
    username = "yourusername";
    homeDirectory = "/Users/yourusername";
    signingKey = "ssh-ed25519 AAAA...your-public-key";
  };

  accounts = {
    opAccount = "YOUR-1PASSWORD-ACCOUNT-ID";
    awsProfiles = {
      default = {
        region = "us-east-1";
        opItem = "your-1password-item-id";
      };
      secondary = {
        name = "profile-name";
        region = "eu-central-1";
        opItem = "your-1password-item-id";
      };
    };
  };

  machine = {
    computerName = "your-hostname";
  };

  apiKeys = {
    bear = "your-bear-api-token";
    circleci = "your-circleci-token";
    slackUser = "xoxp-your-slack-user-token";
  };

  hetznerS3BearMcp = {
    accessKey = "your-hetzner-s3-access-key";
    secretKey = "your-hetzner-s3-secret-key";
  };

  googleChat = {
    clientId = "your-google-oauth-client-id.apps.googleusercontent.com";
    clientSecret = "your-google-oauth-client-secret";
    projectId = "your-gcp-project-id";
  };

  ssh = {
    storagebox = {
      hostname = "your-storagebox.de";
      user = "your-storagebox-user";
    };
    paperless = {
      hostname = "0.0.0.0";
      port = 22;
      user = "paperless";
    };
    synology = {
      hostname = "192.168.1.10";
      user = "yourusername";
    };
    dobby = {
      hostname = "192.168.1.12";
      user = "yourusername";
    };
    macmini = {
      hostname = "192.168.1.11";
      user = "yourusername";
    };
    garageHetzner = {
      hostname = "0.0.0.0";
    };
    nix = {
      hostname = "0.0.0.0";
      user = "root";
    };
    simplyTm = {
      hostname = "your-host.example.com";
      user = "your-domain.com";
    };
    k3s = {
      hostname = "0.0.0.0";
      user = "root";
      identityFile = "~/.ssh/id_rsa-your-key";
    };
  };
}
