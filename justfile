# Update screenpipe to the latest release
update-screenpipe:
    #!/usr/bin/env bash
    set -euo pipefail
    FILE="packages/screenpipe.nix"

    # Get latest version tag (strip 'v' prefix)
    LATEST=$(curl -sL "https://api.github.com/repos/screenpipe/screenpipe/releases" \
        | jq -r '[.[] | select(.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))][0].tag_name' \
        | sed 's/^v//')
    CURRENT=$(sed -n 's/.*version = "\(.*\)";/\1/p' "$FILE")

    if [ "$LATEST" = "$CURRENT" ]; then
        echo "screenpipe is already at latest version ($CURRENT)"
        exit 0
    fi

    echo "Updating screenpipe: $CURRENT -> $LATEST"

    # Prefetch hash for aarch64-darwin
    URL="https://github.com/screenpipe/screenpipe/releases/download/v${LATEST}/screenpipe-${LATEST}-aarch64-apple-darwin.tar.gz"
    HASH=$(nix-prefetch-url "$URL" 2>/dev/null)
    SRI=$(nix-shell -p nix --run "nix hash to-sri --type sha256 $HASH" 2>/dev/null)

    echo "  aarch64-darwin hash: $SRI"

    # Update version
    sed -i '' "s/version = \"$CURRENT\"/version = \"$LATEST\"/" "$FILE"

    # Update aarch64-darwin hash
    sed -i '' "s|hash = \"sha256-.*\"; # aarch64-darwin|hash = \"$SRI\"; # aarch64-darwin|" "$FILE"
    # Fallback if no comment marker exists
    if ! grep -q "$SRI" "$FILE"; then
        # Replace the first sha256 hash (aarch64-darwin is first in file)
        sed -i '' "0,/hash = \"sha256-[^\"]*\"/s|hash = \"sha256-[^\"]*\"|hash = \"$SRI\"|" "$FILE"
    fi

    echo "Updated $FILE to v$LATEST"
    echo "Run 'hs' to build and apply"
