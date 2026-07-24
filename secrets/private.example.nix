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

  schedule = {
    # icalBuddy calendar names drawn in the sketchybar schedule strip (exact,
    # comma-separated). `icalBuddy calendars` lists the available names.
    calendars = "Personal,you@work.example.com";
  };

  apiKeys = {
    circleci = "your-circleci-token";
    slackUser = "xoxp-your-slack-user-token";
  };

  clickhouse = {
    host = "your-instance.region.aws.clickhouse.cloud";
    user = "default";
    opItem = "your-1password-item-id";
  };

  ssh = {
    storagebox = {
      hostname = "your-storagebox.de";
      user = "your-storagebox-user";
    };
    storageboxAudiobooks = {
      hostname = "your-storagebox.de";
      port = 23;
      user = "your-storagebox-sub-user";
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
    oci1 = {
      hostname = "0.0.0.0";
      user = "ubuntu";
      identityFile = "~/.ssh/id_rsa-your-key";
    };
    oci2 = {
      hostname = "0.0.0.0";
      user = "ubuntu";
      identityFile = "~/.ssh/id_rsa-your-key";
    };
  };
}
