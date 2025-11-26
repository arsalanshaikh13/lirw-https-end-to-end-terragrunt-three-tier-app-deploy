#!/bin/bash
set -euo pipefail

# Find every terragrunt.hcl file
find . -type f -name "terragrunt.hcl" | while read -r file; do
    echo "Processing: $file"

    # Remove before_hook_1
    sed -i.bak '/before_hook "before_hook_1" {/,/}/d' "$file"

    # Remove before_hook_2
    sed -i.bak '/before_hook "before_hook_2" {/,/}/d' "$file"

    # Cleanup backup file if you want
    rm -f "${file}.bak"
done

echo "Done."
