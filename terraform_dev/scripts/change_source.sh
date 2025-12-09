#!/bin/bash

# # Script to update source lines in terragrunt.hcl files.
# # Comments out the old source line and adds the new TFR source.

set -euo pipefail

# Get target directory from argument or use current directory
TARGET_DIR="${1:-.}"

echo "Searching for terragrunt.hcl files in: $TARGET_DIR"
echo ""

# Counters
updated_count=0
skipped_count=0

# Arrays to store file paths
declare -a updated_files
declare -a skipped_files

# Find all terragrunt.hcl files and process them
while IFS= read -r -d '' file; do
    echo "Processing: $file"
    
    # Check if the file contains the pattern we're looking for
    # Set +e temporarily to allow grep to return non-zero without exiting
    set +e
    grep -q 'source[[:space:]]*=[[:space:]]*"\${path_relative_from_include("root")}/modules/' "$file"
    grep_result=$?
    set -e
    
    if [ $grep_result -eq 0 ]; then
        # Pattern found - update the file
        # Create a temporary file
        temp_file=$(mktemp)
        
        # Process the file with sed
        sed -E 's|^([[:space:]]*)source[[:space:]]*=[[:space:]]*"\$\{path_relative_from_include\("root"\)\}/modules/([^/]+)/([^"]+)"|\1# source = "${path_relative_from_include(\"root\")}/modules/\2/\3"\n\1source = "tfr://gitlab.com/arsalanshaikh13/tf-modules-lirw-packer/aws//\2/\3?version=1.0.0-lirw-packer"|g' "$file" > "$temp_file"
        
        # Replace original file with updated content
        mv "$temp_file" "$file"
        
        echo "  ✓ Updated"
        updated_files+=("$file")
        # ((updated_count++))
        updated_count=$((updated_count+1))
    else
        echo "  ⊘ Skipped (pattern not found)"
        skipped_files+=("$file")
        # ((skipped_count++))
        skipped_count=$((skipped_count+1))
    fi
done < <(find "$TARGET_DIR" -name "terragrunt.hcl" -type f -print0)

# Print summary
echo ""
echo "============================================================"
echo "Summary:"
echo "  Updated: $updated_count files"
echo "  Skipped: $skipped_count files"
echo "============================================================"

if [ $updated_count -gt 0 ]; then
    echo ""
    echo "Updated files:"
    for f in "${updated_files[@]}"; do
        echo "  - $f"
    done
fi


# Script to update source lines in terragrunt.hcl files.
# Comments out the old source line and adds the new TFR source.

# set -euo pipefail

# # Get target directory from argument or use current directory
# TARGET_DIR="${1:-.}"

# echo "Searching for terragrunt.hcl files in: $TARGET_DIR"
# echo ""

# # Counters
# updated_count=0
# skipped_count=0

# # Arrays to store file paths
# declare -a updated_files
# declare -a skipped_files

# # Store all terragrunt.hcl files in an array first
# mapfile -d '' all_files < <(find "$TARGET_DIR" -name "terragrunt.hcl" -type f -print0)

# echo "Found ${#all_files[@]} terragrunt.hcl file(s)"
# echo ""

# # Process each file
# for file in "${all_files[@]}"; do
#     echo "Processing: $file"
    
#     # Check if the file contains the pattern we're looking for
#     # Set +e temporarily to allow grep to return non-zero without exiting
#     set +e
#     grep -q 'source[[:space:]]*=[[:space:]]*"\${path_relative_from_include("root")}/modules/' "$file"
#     grep_result=$?
#     set -e
    
#     if [ $grep_result -eq 0 ]; then
#         # Pattern found - update the file
#         # Create a temporary file
#         temp_file=$(mktemp)
        
#         # Process the file with sed
#         sed -E 's|^([[:space:]]*)source[[:space:]]*=[[:space:]]*"\$\{path_relative_from_include\("root"\)\}/modules/([^/]+)/([^"]+)"|\1# source = "${path_relative_from_include(\"root\")}/modules/\2/\3"\n\1source = "tfr://gitlab.com/arsalanshaikh13/tf-modules-lirw-packer/aws//\2/\3?version=1.0.0-lirw-packer"|g' "$file" > "$temp_file"
        
#         # Replace original file with updated content
#         mv "$temp_file" "$file"
        
#         echo "  ✓ Updated"
#         updated_files+=("$file")
#         updated_count=$((updated_count+1))
#     else
#         echo "  ⊘ Skipped (pattern not found)"
        # skipped_files+=("$file")
        # # ((skipped_count++))
        # skipped_count=$((skipped_count+1))
#     fi
# done

# # Print summary
# echo ""
# echo "============================================================"
# echo "Summary:"
# echo "  Updated: $updated_count files"
# echo "  Skipped: $skipped_count files"
# echo "============================================================"

# if [ $updated_count -gt 0 ]; then
#     echo ""
#     echo "Updated files:"
#     for f in "${updated_files[@]}"; do
#         echo "  - $f"
#     done
# fi