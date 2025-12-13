#!/bin/bash
set -euo pipefail

TARGET_FOLDER="$1"
NEW_VERSION="$2"


if [[ ! -d "$TARGET_FOLDER" ]]; then
    echo "❌ Folder not found: $FILE"
    echo "Usage: $0 <folder-name> <new-version>"
    exit 1
fi

if [[ -z "$NEW_VERSION" ]]; then
    echo "❌ New version not provided"
    echo "Usage: $0 <folder-name> <new-version>"
    exit 1
fi

echo "🔍 Searching for '$TARGET_FOLDER' folders..."

# Find and process all matching terragrunt.hcl files in one go
find terraform_* -type d -name "$TARGET_FOLDER" -exec sh -c '
    file="$1/terragrunt.hcl"
    version="$2"
    
    [[ ! -f "$file" ]] && exit 0
    
    echo "📄 $file"
    cp "$file" "$file.bak"
    sed -i  -E "s|(source[[:space:]]*=[[:space:]]*\"tfr://[^\"]*\?version=)[^\"]*|\1$version|g" "$file"
    echo "   ✅ Updated to $version"
    rm -f "$file.bak"
' sh {} "$NEW_VERSION" \;

echo "🎉 Done!"