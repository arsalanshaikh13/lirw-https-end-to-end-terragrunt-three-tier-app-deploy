#!/bin/bash

# dir=$(pwd)
# for folder in $dir; do
#     find $folder -type f "terragrunt.hcl" -exec mv {} terragrunt_old.hcl \;
# done

# dry run operation
# find .. -type f -name "terragrunt.hcl" \
#     -exec sh -c 'echo zz "$1" "${1%.hcl}_old.hcl"' _ {} \;
# find .. -type f -name "terragrunt.hcl" -print0 \
#     | xargs -0 -I {} sh -c 'echo zz "{}" "${1%.hcl}_old.hcl"' _ {}
# find .. -type f -name "terragrunt.hcl" -print0 \
#     | xargs -0 sh -c 'for f; do echo zz "$f" "${f%.hcl}_old.hcl"; done' _
# find ../terraform_old -type d -name "modules*" -print0 \
#     | xargs -0 sh -c 'for d; do echo rm -rf "$d" ; done' _

# move operation
# find ../terraform_old -type f -name "terragrunt.hcl" -print0 \
#     | xargs -0 sh -c 'for f; do mv -v "$f" "${f%.hcl}_old.hcl"; done' _

# find ../terraform_old -type d -name "modules*" -print0 \
#     | xargs -0 sh -c 'for d; do rm -rfv "$d" ; done' _
find .. -type f -name "*.dot*" -print0 \
    | xargs -0 sh -c 'for f; do rm -rfv "$f" ; done' _


# find . -type d -mindepth 1 -maxdepth 1 \
#     -exec sh -c '
#         for dir; do
#             echo cp "./build_ami_old1.sh" "$dir/"
#         done
#     ' _ {} +
# _ is $0 and {} is $1 positional arguments