#!/bin/bash
set -xeuo pipefail
# find . -name terragrunt.hcl -exec sed -i '' \
# '/^source = "\${path_relative_from_include("root")}/modules\/$(basename $(dirname $(pwd)))\/$(basename $(pwd)))"/{
# s/^/# /
# a\
# source = "tfr://gitlab.com/arsalanshaikh13/tf-modules-lirw-packer/aws//$(basename $(dirname $(pwd)))/$(basename $(pwd)))?version=1.0.0-lirw-packer"
# }' {} +

# find . -name terragrunt.hcl | while read -r file; do
#   dir="$(dirname "$file")"
#   current_dir="$(basename "$dir")"
#   parent_dir="$(basename "$(dirname "$dir")")"

#   sed -i '' \
#   "/^source = \"\${path_relative_from_include(\"root\")}.*/{
#     s/^/# /
#     a\\
# source = \"tfr://gitlab.com/arsalanshaikh13/tf-modules-lirw-packer/aws//${parent_dir}/${current_dir}?version=1.0.0-lirw-packer\"
#   }" "$file"
# done

find . -name terragrunt.hcl -exec sh -c '
  for file; do
    dir=$(dirname "$file")
    parent=$(basename "$(dirname "$dir")")
    current=$(basename "$dir")
    
    sed -i "" \
      "/^[[:space:]]*source[[:space:]]*=[[:space:]]*\"\${path_relative_from_include(\"root\")}\\/modules\\/${parent}\\/${current}\"/{
        s/^/# /
        a\\
  source = \"tfr://gitlab.com/arsalanshaikh13/tf-modules-lirw-packer/aws//${parent}/${current}?version=1.0.0-lirw-packer\"
      }" "$file"
  done
' sh {} +