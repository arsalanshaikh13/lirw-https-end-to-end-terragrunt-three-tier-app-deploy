#!/usr/bin/env bash
set -euo pipefail

# Find a folder by climbing upward
# go_up_until() {
#     if [[ $# -ne 1 ]]; then
#         echo "Usage: go_up_until <folder_name>" >&2
#         echo "Usage: go_up_until <folder_name/sub_folder_name>" >&2
#         return 1
#     fi
    
#     local name="$1"

#     # this also works for exact matches but separates dirname with basename
#     # pattern_name="${name%%/*}"
#     # subfolder_path="${name##*/}"

#     name="${name#./}" # exactmatch of the folder is required

#     local dir="$(pwd)"
#     while [[ "$dir" != "/" ]]; do
#         if [[ -d "$dir/$name" ]]; then
#         # if [[ -d $dir/$pattern_name/$subfolder_path ]]; then
#             echo "$dir/$name"
#             # echo $dir/$pattern_name/$subfolder_path
#             return 0
#         fi
#         dir="$(dirname "$dir")"
#     done
#     echo "Error: Folder '$name' not found above." >&2
#     # echo "Error: Folder '$name' $pattern_name $subfolder_path not found above." >&2
#     return 1
# }

go_up_until() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: go_up_until <folder_name(glob-pattern)>" >&2
        echo "example: go_up_until folder_name/sub_folder_name" >&2
        echo "example: go_up_until folder_name*" >&2
        echo "example: go_up_until folder_name*/sub_folder_name" >&2
        echo "example: go_up_until folder_name?/sub_folder_name*" >&2

        return 1
    fi

    local input="$1"
    local mode="exact"
    # local mode="regex"
    local dir="$(pwd)"

    # Detect regex (character class for common regex tokens)
    # if [[ "$input" =~ [\^\.\+\?\|\(\)\[\]\$] ]]; then
    #     mode="regex"
    # elif [[ "$input" =~ [\*\?] ]]; then
    #     mode="glob"
    # else
    #     mode="exact"
    # fi
    if [[ "$input" =~ (\[|\]|\(|\)|\+|\?|\||\^|\$) ]]; then
        mode="regex"
    elif [[ "$input" =~ [\*\?] ]]; then
        mode="glob"
    else
        mode="exact"
    fi


    # Walk upward until root
    while [[ "$dir" != "/" ]]; do

        case "$mode" in

            exact)
                # FAST: only check the exact path
                if [[ -d "$dir/$input" ]]; then
                    echo "$dir/$input"
                    return 0
                fi
                ;;

            glob)

                # ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform "lirw-terragr*/terraf*"
                # ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform lirw-terragr*/terraf*
                # ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform terraf*
                # ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform /terraf*

                if glob_with_subdir_match "$dir" "$input"; then
                    return 0
                fi
                ;;

            regex)
                # MUST scan directory entries for regex match
                # this doesn't work 
                # for path in "$dir"/*; do
                #     [[ -e "$path" ]] || continue

                #     base="$(basename "$path")"
                #     if [[ "$base" =~ $input ]]; then
                #         echo "$path"
                #         return 0
                #     fi
                # done

                # ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform "lirw-terragr[^/]+/terraf[^/]+"
                # ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform lirw-terragr[^/]+/terraf[^/]+
                # ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform terraf[^/]+
                # ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform /terraf[^/]+
                if regex_match "$dir" "$input"; then
                    return 0
                fi

                ;;
        esac

        # Go up one level
        dir="$(dirname "$dir")"
    done

    echo "Error: '$input' not found above. (mode: $mode)" >&2
    return 1
}


glob_with_subdir_match() {
    local dir="$1"
    local input="$2"
    
     # Case 1: NO slash → simple glob match inside dir
    
    if [[ "$input" != */* ]]; then

        match=$(find $dir -type d -name "${input}" -print -quit)
        # match=$(find $dir -type d -wholename "${dir}/${input}" -print -quit) # this does depth first search so it recursively goes into subdirectories so it is less reliable
        # /ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraf* terrag*/pack* find -wholename version returned at the end.git/objects/pack
        if [[ -n $match ]]; then
            echo $match
            return 0
        fi
        return 1
    #     local pattern="$input"

    #     for match in "$dir"/$pattern; do
    #         [[ -d "$match" ]] || continue

    #         echo "$match"
    #         return 0
    #     done

    #     return 1
    fi

    # Case 2: Has slash → parent_glob/child_glob
    # Split pattern into parent glob + child dir
    parent_glob="${input%%/*}"   # everything before /
    child_glob="${input##*/}"         # everything after  /

    # Expand parent glob inside current dir
        
        # for expanded in "$dir"/$parent_glob; do
        #     [[ -d "$expanded" ]] || continue

        #     Now check if the child folder exists
        #     if [[ -d "$expanded/$child_glob" ]]; then
        #         echo "$expanded/$child_glob"
        #         return 0
        #     fi
        #     Expand parent folders
        # done

    for parent in "$dir"/$parent_glob; do  # this is breadth first search so it only looks for the directories inside the folder at top level not inside subdirectories so more reliable in my usecase
    # /ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraf* terrag*/pack* this version returned at the end terragrunt-three-tier/packer

        [[ -d "$parent" ]] || continue

        # Expand child folders inside parent
        for child in "$parent"/$child_glob; do
            [[ -d "$child" ]] || continue

                # echo "$parent/$child"
                echo "$child"
                return 0
        done
    done
    return 1
}

regex_match () {
    local dir="$1"
    local pattern="$2"

    match=$(find "$dir" -type d \
                | grep -Ei "${pattern}$")
    if [[ -n $match ]]; then
        echo $match
        return 0
    fi

    return 1

}


# Go up N levels, then search down for folder
go_up_then_down() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: go_up_then_down <levels> <folder_name>" >&2
        echo "Example: go_up_then_down 3 templates" >&2
        return 1
    fi
    
    local levels="$1"
    local name="$2"
    
    # Validate that levels is a number
    if ! [[ "$levels" =~ ^[0-9]+$ ]]; then
        echo "Error: First argument must be a number (levels to go up)." >&2
        echo "Usage: go_up_then_down <levels> <folder_name>" >&2
        return 1
    fi
    
    local start_dir="$(pwd)"
    
    for ((i=0; i<levels; i++)); do
        start_dir="$(dirname "$start_dir")"
        if [[ "$start_dir" == "/" ]]; then
            echo "Error: Reached root before going up $levels levels." >&2
            return 1
        fi
    done
    
    echo "🔍 Searching from: $start_dir" >&2
    
    local result
    result=$(find "$start_dir" -type d -name "$name" -print -quit 2>/dev/null)
    # result_file=$(find "$result" -type d -name "$file_name" -print -quit 2>/dev/null)
    
    if [[ -z "$result" ]]; then
        echo "Error: Folder '$name' not found below $start_dir." >&2
        return 1
    fi
    
    realpath "$result"
}

# Find ancestor directory by name/pattern
# we can change path to other directory from common ancestor
find_ancestor() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: find_ancestor <pattern>" >&2
        echo "Example: find_ancestor 'project_root'" >&2
        echo "Example: find_ancestor project_root/something" >&2
        echo "Example: find_ancestor project_root/*something*" >&2
        echo "Example: find_ancestor project_root*/*something*" >&2
        return 1
    fi
    
    local ancestor_pattern="$1"
    # local pattern="$1"
    pattern="${ancestor_pattern%%/*}"
    subfolder_path="${ancestor_pattern##*/}"
    # echo "$pattern | $subfolder_path" 
    local dir="$(pwd)"

    while [[ "$dir" != "/" ]]; do
        local basename="$(basename "$dir")"
        # Support both exact match and regex pattern
        if [[ "$basename" == $pattern ]] || [[ "$basename" =~ $pattern ]]; then
            # echo "$dir"
            new_path=$(find "$dir" -type d -name "$subfolder_path" -print -quit 2>/dev/null) 
            if [[ -z "$new_path" ]]; then
                new_path=$dir
            fi
            # echo "found new_path $new_path"
            echo $new_path
            # echo "$dir | $new_path"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "Error: Ancestor matching '$pattern' not found." >&2
    return 1
}

# Copy using ancestor name/pattern
ancestor_based_copy() {
    local dry_run=false
    local ancestor_pattern=""
    local src_name=""
    local dst_name=""
    local file_name=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                # Positional arguments
                if [[ -z "$ancestor_pattern" ]]; then
                    ancestor_pattern="$1"
                elif [[ -z "$src_name" ]]; then
                    src_name="$1"
                elif [[ -z "$dst_name" ]]; then
                    dst_name="$1"
                elif [[ -z "$file_name" ]]; then
                    file_name="$1"
                    # file_name="${1:-}"
                else
                    echo "Error: Too many arguments" >&2
                    return 1
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$ancestor_pattern" || -z "$src_name" || -z "$dst_name" ]]; then
        echo "Usage: ancestor_based_copy [--dry-run] <ancestor_pattern> <source_folder> <dest_folder> [file_name]" >&2
        echo "--dry-run flag can be used anywhere after ancestor_based_copy " >&2
        echo "Example: ancestor_based_copy 'terragrunt/tutorial' compute terraform" >&2
        echo "Example: ancestor_based_copy --dry-run '*terragrunt/terrag*' 'terraf*' 'backen*'" >&2
        echo "Example: ancestor_based_copy  '*terragrunt/terrag*' 'terraf*' 'backen*' --dry-run" >&2
        echo "Example: ancestor_based_copy  '*terragrunt/terrag*' --dry-run 'terraf*' 'backen*' " >&2
        return 1
    fi

    # if [[ $# -ne 3 ]]; then
    # if [[ $# -gt 5 || $# -lt 3 ]]; then
    #     echo "Usage: ancestor_based_copy <ancestor_pattern> <source_folder> <dest_folder> [file_name] [--dry-run]" >&2
    #     echo "Example: ancestor_based_copy 'terragrunt/tutorial' compute terraform" >&2
    #     echo "Example: ancestor_based_copy '*terragrunt/terrag*' 'terraf*' 'backen*'" >&2
    #     echo "Example: ancestor_based_copy '*terragrunt/terrag*' 'terraform terrag*/pack*'"  >&2
    #     return 1
    # fi
    
    # local ancestor_pattern="$1"
    # local src_name="$2"
    # local dst_name="$3"
    # local file_name="${4:-}"  # optional
    # local dry_run="${5:-}"

    # Only set if dry-run is true (avoids empty strings)
    local mode_label=""
    [[ "$dry_run" == true ]] && mode_label="[DRY-RUN]"

    echo "🔍 Finding ancestor matching: $ancestor_pattern $mode_label"
    # echo "🔍 Finding ancestor matching: $ancestor_pattern"
    local ancestor
    ancestor=$(find_ancestor "$ancestor_pattern" )
    echo "📁 Found ancestor: $ancestor"
    
    echo "🔍 Searching for source '$src_name' from ancestor..."
    local src_path
    src_path=$(find "$ancestor" -type d -name "$src_name" -print -quit 2>/dev/null )
    # src_path=$(find "$ancestor" -type d -name "$src_name" -print -quit 2>/dev/null | tee /dev/tty)
    
    if [[ -z "$src_path" ]]; then
        echo "Error: Source folder '$src_name' not found below $ancestor." >&2
        return 1
    fi
    echo "📁 Found source: $src_path"
    
    # echo "🔍 Searching for destination '$dst_name' from ancestor..."
    # local dst_path
    # dst_path=$(find "$ancestor" -type d -name "$dst_name" -print -quit 2>/dev/null)
    
    echo "🔍 Searching for destination '$dst_name' upward from current location..."
    dst_path=$(go_up_until "$dst_name")
    # dst_path=$(go_up_until "$dst_name" | tee /dev/tty)
    echo "📁 Found destination: $dst_path"
    

    if [[ -z "$dst_path" ]]; then
        # echo "Error: Destination folder '$dst_name' not found below $ancestor." >&2
        echo "Error: Destination folder '$dst_name' not found " >&2
        return 1
    fi
    echo "📁 Found destination: $dst_path"
    
    # # echo "📦 Copying from $src_path → $dst_path"
    # # cp -r "$src_path"/* "$dst_path"/

    if [[ -z "$file_name" ]]; then
        echo "📦 Copying ALL files from $src_path → $dst_path"
        if [[ "$dry_run" == false ]]; then
            # cp -r "$src_path"/* "$dst_path"/
            echo "it is NORMAL run"

            return 0
        fi
        echo "it is a dry run, use flags --move or --copy to perform move or copy operation"
        return 0

        # cp -r "$src_path"/* "$dst_path"/
    else
        echo "📄 Copying ONLY file '$file_name'"
        local src_file
        src_file=$(find "$src_path" -type f -name "$file_name" -print -quit 2>/dev/null )
        # src_file=$(find "$src_path" -type f -name "$file_name" -print -quit 2>/dev/null | tee /dev/tty)

        if [[ -z "$src_file" ]]; then
            echo "Error: File '$file_name' not found inside $src_path" >&2
            return 1
        fi

        if [[ "$dry_run" == false ]]; then
            # cp -r "$src_file" "$dst_path"/
            echo "it is NORMAL run"

        fi
        echo "it is a dry run, use flags --move or --copy to perform move or copy operation"
        # cp "$src_file" "$dst_path"/
        return 0
    fi

    echo "✅ Copy done."
}


# move level up and go to the other specified directory from that level
level_based_copy() {

    local dry_run=false
    local up_levels=""
    local src_name=""
    local dst_name=""
    local file_name=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                # Positional arguments
                if [[ -z "$up_levels" ]]; then
                    up_levels="$1"
                elif [[ -z "$src_name" ]]; then
                    src_name="$1"
                elif [[ -z "$dst_name" ]]; then
                    dst_name="$1"
                elif [[ -z "$file_name" ]]; then
                    file_name="$1"
                else
                    echo "Error: Too many arguments" >&2
                    return 1
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$up_levels" || -z "$src_name" || -z "$dst_name" ]]; then
        echo "Usage: level_based_copy [--dry-run] <up_levels> <source_folder> <dest_folder> [file_name]" >&2
        echo "Example: level_based_copy 3 templates config" >&2
        echo "Example: level_based_copy --dry-run 3 templates config config.sh" >&2
        echo "Example: level_based_copy 3 templa* --dry-run confi* conf*.sh" >&2
        return 1
    fi
    # # if [[ $# -ne 3 ]]; then
    # if [[ $# -gt 5 || $# -lt 3 ]]; then
    #     echo "Usage: level_based_copy [--dry-run] <up_levels> <source_folder> <dest_folder> [file_name]" >&2
    #     echo "Example: level_based_copy 3 templates config " >&2
    #     echo "Example: level_based_copy 3 templates config config.sh" >&2
    #     echo "Example: level_based_copy 3 templa* confi* conf*.sh" >&2
    #     return 1
    # fi
    
    # local up_levels="$1"
    # local src_name="$2"
    # local dst_name="$3"
    # local file_name="${4:-}"  # optional
    
    # Validate that up_levels is a number
    if ! [[ "$up_levels" =~ ^[0-9]+$ ]]; then
        echo "Error: First argument must be a number (levels to go up)." >&2
        echo "Usage: level_based_copy <up_levels> <source_folder> <dest_folder>" >&2
        return 1
    fi

    # Only set if dry-run is true (avoids empty strings)
    local mode_label=""
    [[ "$dry_run" == true ]] && mode_label="[DRY-RUN]"

    echo "🔍 Going up $up_levels level(s), then searching for '$src_name'... $mode_label"
    # echo "🔍 Going up $up_levels level(s), then searching for '$src_name'..."
    src_path=$(go_up_then_down "$up_levels" "$src_name" )
    # src_path=$(go_up_then_down "$up_levels" "$src_name" | tee /dev/tty)
    echo "📁 Found source: $src_path"
    
    echo "🔍 Searching for destination '$dst_name' upward from current location..."
    dst_path=$(go_up_until "$dst_name")
    # dst_path=$(go_up_until "$dst_name" | tee /dev/tty)
    echo "📁 Found destination: $dst_path"
    
    # echo "📦 Copying from $src_path → $dst_path"
    # cp -r "$src_path"/* "$dst_path"/
    # cp "$src_path_file" "$dst_path"/

    if [[ -z "$file_name" ]]; then
        echo "📦 Copying ALL files from $src_path → $dst_path"
        if [[ "$dry_run" == false ]]; then
            # cp -r "$src_path"/* "$dst_path"/
            echo "it is NORMAL run"

            return 0
        fi
        echo "it is a dry run, use flags --move or --copy to perform move or copy operation"
        return 0

        # cp -r "$src_path"/* "$dst_path"/
    else
        echo "📄 Copying ONLY file '$file_name'"
        local src_file
        src_file=$(find "$src_path" -type f -name "$file_name" -print -quit)

        if [[ -z "$src_file" ]]; then
            echo "Error: File '$file_name' not found inside $src_path" >&2
            return 1
        fi
        if [[ "$dry_run" == false ]]; then
            # cp -r "$src_file" "$dst_path"/
            echo "it is NORMAL run"
        fi
        echo "it is a dry run, use flags --move or --copy to perform move or copy operation"
        return 0
        # cp "$src_file" "$dst_path"/
    fi

    echo "✅ Copy done."
}

# List all ancestors with their level numbers
list_ancestors() {
    if [[ $# -gt 0 ]]; then
        echo "Usage: list_ancestors" >&2
        echo "Lists all ancestor directories from current location to root." >&2
        return 1
    fi
    
    local dir="$(pwd)"
    # local level="${1:-0}"
    # local level=$1
    local level=0
    
    echo "📋 Ancestors from current directory:"
    echo "   [$level] $(pwd) (current)"
    
    while [[ "$dir" != "/" ]]; do
        dir="$(dirname "$dir")"
        # ((level++))
        # level="$((level++))"
        level=$((level + 1)) # this works when level is starting from 0
        local label=""
        case $level in
            1) label="(parent)" ;;
            2) label="(grandparent)" ;;
            3) label="(great-grandparent)" ;;
            *) label="(${level}th ancestor)" ;;
        esac
        echo "   [$level] $dir $label"
    done
}

# Interactive mode - show ancestors and let user choose
interactive_copy() {
    
    echo "🔍 Available ancestors:"
    list_ancestors
    echo ""
    read -p "Enter ancestor level number or name/pattern: " input
    read -p "source folder name: " src_name
    read -p "Enter destination folder name: " dst_name
    read -p "Enter file name to copy from source to destination: " file_name
    
    missing=()

    [[ -z "$input" ]]     && missing+=("ancestor input")
    [[ -z "$src_name" ]]  && missing+=("source folder name")
    [[ -z "$dst_name" ]]  && missing+=("destination folder name")

    if (( ${#missing[@]} > 0 )); then
        # # 1️⃣ One-liner message
        # echo "❌ Error: Missing: ${missing[*]}." >&2

        # 2️⃣ Multi-line bullet message
        echo "Details:" >&2
        for item in "${missing[@]}"; do
            echo "  - $item not provided" >&2
        done

        return 1
    fi
    # Check if input is a number
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        # nth_ancestor_based_copy "$input" "$src_name" "$dst_name"
        level_based_copy "$input" "$src_name" "$dst_name" "$file_name" 
    else
        ancestor_based_copy "$input" "$src_name" "$dst_name" "$file_name"
    fi
}

# Help function
show_help() {
    cat << 'EOF'
📚 Directory Navigation & Copy Tool

USAGE: ./ancestor.sh [OPTIONS] <command> [arguments...]

OPTIONS:
  -h, --help, --show_help    Show this help message

COMMANDS:

1. list_ancestors
   Lists all ancestors from current directory to root with level numbers
   Usage: ./ancestor.sh list_ancestors

2. go_up_until <folder_name(glob_pattern) | parent_folder/child_folder >
   Find folder by climbing upward from current directory and prints the full path
   Supports: exact names, glob patterns (*, ?), and paths with subdirectories
   Examples:
     ./ancestor.sh go_up_until config
     ./ancestor.sh go_up_until 'lirw-terragr*'
     ./ancestor.sh go_up_until *thre*arc?
     ./ancestor.sh go_up_until 'lirw-terragr*/scripts'
     ./ancestor.sh go_up_until *thre*arc?/*two*

3. go_up_then_down <levels> <folder_name>
   Go up N levels, then search downward for a folder  and print the full path
   Examples:
     ./ancestor.sh go_up_then_down 3 terraform
     ./ancestor.sh go_up_then_down 2 compute

4. find_ancestor <pattern | pattern/subfolder>
   Find ancestor directory by name/pattern, optionally with subfolder path and print the full path
   Supports both exact match and glob patterns
   
   Examples:
     ./ancestor.sh find_ancestor 'project_root'
     ./ancestor.sh find_ancestor 'project_root/something'
     ./ancestor.sh find_ancestor *arch/three*terragrun?
     ./ancestor.sh find_ancestor 'arch*/three*archi*retry'

5. ancestor_based_copy <ancestor_pattern> <source_folder> <dest_folder> [file_name]
   Copy files using ancestor pattern to locate source and destination
   - Finds ancestor matching the pattern
   - Searches downward from ancestor for source folder
   - Searches upward from current location for destination folder
   - Copies  specific folder
   - Optionally copies only a specific file

   
   Examples:
     ./ancestor.sh ancestor_based_copy 'project_root' templates config
     ./ancestor.sh ancestor_based_copy '*proj.*' src build
     ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform 'lirw-terragr*/terraf*'
     ./ancestor.sh ancestor_based_copy 'arch/three*archi*retry' terraform 'terraf*' main.tf

6. level_based_copy <up_levels> <source_folder> <dest_folder> [file_name]
   Go up N levels, find source folder downward, find destination upward
   - Goes up specified number of levels from current directory
   - Searches downward from that point for source folder
   - Searches upward from current location for destination folder
   - Copies specific folder
   - Optionally copies only a specific file
   
   Examples:
     ./ancestor.sh level_based_copy 4 terraform terraform
     ./ancestor.sh level_based_copy 4 terraform lirw-terragrunt/terraform
     ./ancestor.sh level_based_copy 4 terraform terraf*
     ./ancestor.sh level_based_copy 4 terraform lirw-terragr*/terraf*

7. interactive_copy
   Interactive mode - shows ancestor list and prompts for all inputs
   - Lists all ancestors with level numbers
   - Prompts for ancestor level/pattern, source folder, destination folder, and optional file name
   - Automatically determines whether to use level-based or pattern-based copy
   
   Usage: ./ancestor.sh interactive_copy

GLOB PATTERN EXAMPLES:
  *              Matches any characters
  ?              Matches single character
  project*       Matches: project, project-main, project123
  *config*       Matches: myconfig, config-prod, old-config-backup
  proj???        Matches: project, proj123 (exactly 3 chars after proj)
  parent*/child  Matches: parent-a/child, parent-xyz/child

COMMON USE CASES:
  # Find and navigate to a config folder above current directory
  cd "$(./ancestor.sh go_up_until config)"
  
  # Find a folder with glob pattern including subdirectory
  ./ancestor.sh go_up_until 'lirw-terragrunt*/scripts'
  
  # Copy all files from templates to config using ancestor pattern
  ./ancestor.sh ancestor_based_copy 'myproject' templates config
  
  # Copy specific file from source to destination going up 3 levels
  ./ancestor.sh level_based_copy 3 templates config setup.sh
  
  # Interactive mode for guided copying
  ./ancestor.sh interactive_copy

SOURCING THE SCRIPT:
  You can source this script and call functions directly in your shell:
  
  source ./ancestor.sh
  list_ancestors
  go_up_until 'config'
  ancestor_based_copy 'myproject' src build
  level_based_copy 3 templates config main.tf
EOF
}

# Main command dispatcher
main() {
    # Handle help flags
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    case "$1" in
        -h|--help|--show_help|help)
            show_help
            exit 0
            ;;
        list_ancestors)
            shift
            list_ancestors "$@"
            ;;
        ancestor_based_copy)
            shift
            ancestor_based_copy "$@"
            ;;
        level_based_copy)
            shift
            level_based_copy "$@"
            ;;
        interactive_copy)
            shift
            interactive_copy "$@"
            ;;
        go_up_until)
            shift
            go_up_until "$@"
            ;;
        find_ancestor)
            shift
            find_ancestor "$@"
            ;;
        go_up_then_down)
            shift
            go_up_then_down "$@"
            ;;
        *)
            echo "Error: Unknown command '$1'" >&2
            echo "Run './ancestor.sh --help' for usage information." >&2
            exit 1
            ;;
    esac
}

# Only run main if script is executed (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi



# ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform lirw-terragr*/terraf* main.tf
# ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform lirw-terragr*/terraf* 
# ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform terraf* 
# ./ancestor.sh ancestor_based_copy arch*/three*archi*retry terraform terraf* 
# ./ancestor.sh ancestor_based_copy arch/three*archi*retry terraform terraf* 
# ./ancestor.sh ancestor_based_copy arch/*retry terraform terraf* 


# for regex matching
# ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform "lirw-terragr[^/]+/terraf[^/]+"
# ./ancestor.sh ancestor_based_copy 'arch*/three*archi*retry' terraform lirw-terragr[^/]+/terraf[^/]+