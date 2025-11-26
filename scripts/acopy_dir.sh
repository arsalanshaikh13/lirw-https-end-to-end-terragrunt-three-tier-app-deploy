#!/bin/bash 
set -euo pipefail

# # SOURCE="$(realpath path/to/source)"
# # DEST="$(realpath path/to/dest)"

# # cp -r "$SOURCE"/* "$DEST"/
# # cp "$SOURCE"/*.sh "$DEST"/

# # SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# # ROOT_DIR="$(realpath "$SCRIPT_DIR/../..")"

# # cp -r "$ROOT_DIR/source_folder"/* "$ROOT_DIR/dest_folder"/
# # cp "$ROOT_DIR/source_folder"/*.sh "$ROOT_DIR/dest_folder"/

# # SOURCE="/path/to/source"
# # DEST="/path/to/dest"

# # mkdir -p "$DEST"

# # # Copy everything
# # cp -r "$SOURCE"/* "$DEST"/

# # # Copy only .sh files recursively
# # find "$SOURCE" -type f -name "*.sh" -exec cp {} "$DEST"/ \;

# # TARGET=$(pwd)
# # while [[ "$TARGET" != "/" ]]; do
# #     if [[ -d "$TARGET/modules" ]]; then
# #         echo "Found modules at: $TARGET"
# #         break
# #     fi
# #     TARGET=$(dirname "$TARGET")
# # done
# # cp -r "$SOURCE" "$TARGET/modules/"

# go_up() {
#   local n=$1
#   local p="."
#   for ((i=0; i<n; i++)); do
#     p="../$p"
#   done
#   realpath "$p"
# }

# # echo $DEST
# SOURCE="$(realpath $1)"
# DEST=$(go_up $2)
# # DEST="$(realpath path/to/dest)"

# cp -r "$SOURCE"/ "$DEST"/
# cp "$SOURCE"/*.sh "$DEST"/

# # cp -r ./somefolder "$DEST"/



# # Find a folder by climbing upward
# go_up_until() {
#     local name="$1"
#     local dir="$(pwd)"

#     while [[ "$dir" != "/" ]]; do
#         if [[ -d "$dir/$name" ]]; then
#             echo "$dir/$name"
#             return 0
#         fi
#         dir="$(dirname "$dir")"
#     done

#     echo "Error: Folder '$name' not found above." >&2
#     return 1
# }

# # Find a folder by searching downward from current directory
# go_down_until() {
#     local name="$1"
#     local result

#     result=$(find . -type d -name "$name" -print -quit)
#     echo "result: $result"
    
#     if [[ -z "$result" ]]; then
#         echo "Error: Folder '$name' not found below." >&2
#         return 1
#     fi

#     # return full path (without leading ./)
#     realpath "$result"
# }

# # Copy folder contents dynamically
# dynamic_copy() {
#     local src_name="$1"
#     local dst_name="$2"
#     echo "$src_name $dst_name"
#     echo "🔍 Searching for source folder '$src_name' downward..."
#     src_path=$(go_down_until "$src_name")
#     echo "📁 Found source: $src_path"

#     echo "🔍 Searching for destination folder '$dst_name' upward..."
#     dst_path=$(go_up_until "$dst_name")
#     echo "📁 Found destination: $dst_path"

#     echo "📦 Copying from $src_path → $dst_path"
#     # cp -r "$src_path"/* "$dst_path"/
#     echo "✅ Copy done."
# }

# dynamic_copy $1 $2



# Find a folder by climbing upward
go_up_until() {
    local name="$1"
    local dir="$(pwd)"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/$name" ]]; then
            echo "$dir/$name"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "Error: Folder '$name' not found above." >&2
    return 1
}

# Go up N levels, then search down for folder
go_up_then_down() {
    local levels="$1"
    local name="$2"
    local start_dir="$(pwd)"
    
    # Go up N levels
    for ((i=0; i<levels; i++)); do
        start_dir="$(dirname "$start_dir")"
        if [[ "$start_dir" == "/" ]]; then
            echo "Error: Reached root before going up $levels levels." >&2
            return 1
        fi
    done
    
    echo "🔍 Searching from: $start_dir" >&2
    
    # Search down from that point
    local result
    result=$(find "$start_dir" -type d -name "$name" -print -quit 2>/dev/null)
    
    if [[ -z "$result" ]]; then
        echo "Error: Folder '$name' not found below $start_dir." >&2
        return 1
    fi
    
    realpath "$result"
}

# Find a folder by searching downward from current directory
go_down_until() {
    local name="$1"
    local result
    result=$(find . -type d -name "$name" -print -quit 2>/dev/null)
    
    if [[ -z "$result" ]]; then
        echo "Error: Folder '$name' not found below." >&2
        return 1
    fi
    realpath "$result"
}

# Copy with flexible navigation
# Usage: smart_copy <up_levels> <src_folder_name> <dst_folder_name>
smart_copy() {
    local up_levels="$1"
    local src_name="$2"
    local dst_name="$3"
    
    echo "🔍 Going up $up_levels level(s), then searching for '$src_name'..."
    src_path=$(go_up_then_down "$up_levels" "$src_name")
    echo "📁 Found source: $src_path"
    
    echo "🔍 Searching for destination '$dst_name' upward from current location..."
    dst_path=$(go_up_until "$dst_name")
    echo "📁 Found destination: $dst_path"
    
    echo "📦 Copying from $src_path → $dst_path"
    # cp -r "$src_path"/* "$dst_path"/
    echo "✅ Copy done."
}

# smart_copy $1 $2 $3

# Alternative: Auto-detect common ancestor
auto_copy() {
    local src_name="$1"
    local dst_name="$2"
    
    echo "🔍 Searching for common ancestor..."
    local dir="$(pwd)"
    local found=false
    
    while [[ "$dir" != "/" ]]; do
        # Search down from this level for both folders
        local src=$(find "$dir" -type d -name "$src_name" -print -quit 2>/dev/null)
        local dst=$(find "$dir" -type d -name "$dst_name" -print -quit 2>/dev/null)
        
        if [[ -n "$src" && -n "$dst" ]]; then
            echo "📁 Found both folders from ancestor: $dir"
            echo "   Source: $src"
            echo "   Destination: $dst"
            echo "📦 Copying..."
            # cp -r "$src"/* "$dst"/
            echo "✅ Copy done."
            return 0
        fi
        
        dir="$(dirname "$dir")"
    done
    
    echo "Error: Could not find both folders from a common ancestor." >&2
    return 1
}

auto_copy $1 $2