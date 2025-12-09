#!/bin/bash
set -euo pipefail

SEARCH_DIR="."
NEW_BLOCK=$(cat <<'EOF'
      required_var_files = ["${get_parent_terragrunt_dir("root")}/configuration/prod/terraform.tfvars"]
EOF
)

find "$SEARCH_DIR" -type f -name "terragrunt.hcl" | while read -r file; do
  echo "Processing $file"

  # Skip if already applied
  if grep -q 'configuration/prod/terraform.tfvars' "$file"; then
    echo "  ✔ Already updated"
    continue
  fi
#   # Skip if already applied
#   if grep -q 'configuration/prod/terraform.tfvars' "$file"; then
#     echo "  ✔ Already updated"
#     continue
#   fi

  awk -v block="$NEW_BLOCK" '
    /^[[:space:]]*#[[:space:]]*required_var_files / { print; next }   # skip commented lines

    /required_var_files *=/ {
        print "# " $0   # comment original line
        print block     # insert new block
        next
    }
    { print }
  ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"


  echo "  ✔ Modified with commented original"
done

echo "🎉 Done."

# for version where required_var_files has configuration/dev/terraform.tfvars
# awk -v block="$NEW_BLOCK" '
#     /^[[:space:]]*#[[:space:]]*required_var_files / { print; next }   # skip commented lines

#     /required_var_files *=/ {
#         print block     # insert new block or
#         print "     "block     # or add space before block and then add
#         next
#     }
#     { print }
#   ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
