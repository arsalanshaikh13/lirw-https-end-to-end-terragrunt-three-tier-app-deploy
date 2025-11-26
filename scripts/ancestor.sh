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
  
    # setting timeout limit to retrict while loop search and once again check the valid path entered for destination path
    # bash built in to keep track of time as bash always increments the SECONDS variable
    # Reset the timer just for this block
    SECONDS=0 
    timeout=2   # seconds
    # start=$(date +%s)
    
    local error
    # Walk upward until root
    while [[ "$dir" != "/" ]]; do

        # now=$(date +%s)
        # if (( now - start > timeout )); then
        if (( SECONDS > timeout )); then
            echo "Error: operation timed out after ${timeout}s  check the path input $input" >&2
            return 1
            # break
        fi

        case "$mode" in

            exact)
                # FAST: only check the exact path
                # if [[ -d "$dir/$input" ]]; then
                #     echo "$dir/$input"
                #     return 0
                # fi
                # if glob_with_subdir_match "$dir" "$input"; then
                #     return 0
                # fi
                found_path=$(glob_with_subdir_match "$dir" "$input")
                if [[ -n $found_path ]]; then
                    echo $found_path
                    return 0
                fi
                ;;

            glob)

                # ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform "lirw-terragr*/terraf*"
                # ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform lirw-terragr*/terraf*
                # ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform terraf*
                # ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform /terraf*
                # if glob_with_subdir_match "$dir" "$input"; then
                #     return 0
                # fi
                found_path=$(glob_with_subdir_match "$dir" "$input")
                if [[ -n $found_path ]]; then
                    echo $found_path
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

                # ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform "lirw-terragr[^/]+/terraf[^/]+"
                # ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform lirw-terragr[^/]+/terraf[^/]+
                # ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform terraf[^/]+
                # ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform /terraf[^/]+
                if regex_match "$dir" "$input"; then
                    return 0
                fi

                ;;
        esac

        # Go up one level
        dir="$(dirname "$dir")"
        # base_name="$(basename "$dir")"
    done

    current_dir=$(pwd)
    echo "Error: '$input' not found in any of the parent directories in the path $current_dir . (mode: $mode) try glob-pattern or parent_dir/child_dir pattern or verify folder name" >&2
    return 1
}


# glob_with_subdir_match() {
#     local dir="$1"
#     local input="$2"
    
#      # Case 1: NO slash → simple glob match inside dir
    
#     if [[ "$input" != */* ]]; then

#         match=$(find $dir -type d -name "${input}" -print -quit)
#         # match=$(find $dir -maxdepth 1 -type d -wholename "${dir}/${input}" -print -quit) # this does depth first search so it recursively goes into subdirectories so it is less reliable
#         # /ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraf* terrag*/pack* find -wholename version returned at the end.git/objects/pack 
#         # with maxdepth 1 it is working fine
#         if [[ -n $match ]]; then
#             echo $match
#             return 0
#         fi
#         # only throw this error when calling function which has while loop has searched all the paths till the root
#         if [[ "$dir" == "/" ]]; then
#             echo "Error: '$input' not found in any of the  directories in the path. Try glob-pattern or parent_dir/child_dir pattern or verify folder name or glob pattern" >&2
#             return 1
#         fi
#         # echo "Error: '$input' not found in any of the  directories in the path. Try glob-pattern or parent_dir/child_dir pattern or verify folder name or glob pattern" >&2
#         # return 1
#     #     local pattern="$input"

#     #     for match in "$dir"/$pattern; do
#     #         [[ -d "$match" ]] || continue

#     #         echo "$match"
#     #         return 0
#     #     done

#     #     return 1
#     fi

#     # Case 2: Has slash → parent_glob/child_glob
#     # Split pattern into parent glob + child dir
#     parent_glob="${input%%/*}"   # everything before /
#     child_glob="${input##*/}"         # everything after  /

#     # Expand parent glob inside current dir
        
#         # for expanded in "$dir"/$parent_glob; do
#         #     [[ -d "$expanded" ]] || continue

#         #     Now check if the child folder exists
#         #     if [[ -d "$expanded/$child_glob" ]]; then
#         #         echo "$expanded/$child_glob"
#         #         return 0
#         #     fi
#         #     Expand parent folders
#         # done

#     for parent in "$dir"/$parent_glob; do  # this is breadth first search so it only looks for the directories inside the folder at top level not inside subdirectories so more reliable in my usecase
#     # /ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraf* terrag*/pack* this version returned at the end terragrunt-three-tier/packer

#         [[ -d "$parent" ]] || continue

#         # Expand child folders inside parent
#         for child in "$parent"/$child_glob; do
#             [[ -d "$child" ]] || continue

#                 # echo "$parent/$child"
#                 echo "$child"
#                 return 0
#         done
#     done

#     # only throw this error when calling function which has while loop has searched all the paths till the root
#     if [[ "$dir" == "/" ]]; then

#         echo "Error: '$input' not found in any of the  directories in the path. Try glob-pattern or parent_dir/child_dir pattern or verify folder name or glob pattern" >&2
#         return 1
#     fi
    
#     # return 
# }

# recursive function which allows for any path: path1/path2/path3/....
# glob_with_subdir_match() {
#     local dir="$1"
#     local input="$2"
#     local match
#     # Case 1: NO slash → simple glob match inside dir
#     if [[ "$input" != */* ]]; then
#         # first try breadth first search then depth first search
#         match=$(find "$dir" -maxdepth 1 -type d -name "${input}" -print -quit)
#         if [[ -z $match ]]; then
#             # try depth first search
#             match=$(find "$dir" -maxdepth 10 -type d -name "${input}" -print -quit)
#         fi
        
#         if [[ -n $match ]]; then
#             echo "$match"
#             return 0
#         fi
        
#         if [[ "$dir" == "/" ]]; then
#             echo "Error: '$input' not found in any of the directories in the path. Try glob-pattern or parent_dir/child_dir pattern or verify folder name or glob pattern" >&2
#             return 1
#         fi
#         # return 2  # Signal to continue searching upward
#     fi
    
#     # Case 2: Has slashes → recursively process path components
#     # Split on first / to get first component and rest
#     local first_glob="${input%%/*}"        # everything before first /
#     local rest_path="${input#*/}"          # everything after first /
    
#     # first try breadth first search then depth first search
#     # first_match=$(find "$dir" -maxdepth 10 -type d -name "${first_glob}" -print -quit)
#     first_match=$(find "$dir" -maxdepth 1 -type d -name "${input}" -print -quit)
#     if [[ -z $first_match ]]; then
#         # try depth first search
#         first_match=$(find "$dir" -maxdepth 10 -type d -name "${input}" -print -quit)
#     fi
    
#     if [[ -d "$first_match" ]] ; then
#         local result
#         result=$(glob_with_subdir_match "$first_match" "$rest_path" )
#         local status=$?
        
#         if [[ $status -eq 0 && -n "$result" ]]; then
#             echo "$result"
#             return 0
#         fi
#     fi
#     # # Find all directories matching first glob pattern at current level
#     # for first_match in "$dir"/$first_glob; do
#     #     [[ -d "$first_match" ]] || continue
        
#     #     # Recursively search for rest of path inside this match
#     #     result=$(glob_with_subdir_match "$first_match" "$rest_path" )
#     #     if [[ $? -eq 0 ]]; then
#     #         echo "$result"
#     #         return 0
#     #     fi
#     # done
    
#     # only throw this error when calling function which has while loop has searched all the paths till the root
#     if [[ "$dir" == "/" ]]; then
#         echo "Error: '$input' not found in any of the directories in the path. Try glob-pattern or parent_dir/child_dir pattern or verify folder name or glob pattern" >&2
#         return 1
#     fi
    
#     # return 2  # Signal to continue searching upward
# }

# Helper function to find first matching directory
# Parameters: dir, pattern, search_mode (breadth|depth|auto)
find_first_match() {
    local dir="$1"
    local pattern="$2"
    local search_mode="${3:-auto}"  # default: auto (try breadth first, then depth)
    
    case "$search_mode" in
        breadth)
            find "$dir" -maxdepth 1 -type d -name "$pattern" -print -quit
            ;;
        depth)
            find "$dir" -maxdepth 10 -type d -name "$pattern" -print -quit
            ;;
        auto)
            # Try breadth first, fall back to depth first
            local result
            # try breadth first search
            result=$(find "$dir" -maxdepth 1 -type d -name "$pattern" -print -quit)
            # try depth first search
            if [[ -z $result ]]; then
                result=$(find "$dir" -maxdepth 10 -type d -name "$pattern" -print -quit)
            fi
            echo "$result"
            ;;
    esac
}

# Recursive function which allows for any path: path1/path2/path3/....
# Parameters: dir, input, search_mode (breadth|depth|auto)
glob_with_subdir_match() {
    local dir="$1"
    local input="$2"
    local search_mode="${3:-auto}"
    
    # Case 1: NO slash → simple glob match inside dir
    if [[ "$input" != */* ]]; then
        local match
        match=$(find_first_match "$dir" "$input" "$search_mode")
        
        if [[ -n $match ]]; then
            echo "$match"
            return 0
        fi
        
        if [[ "$dir" == "/" ]]; then
            echo "Error: '$input' not found in any of the directories in the path. Try glob-pattern or parent_dir/child_dir pattern or verify folder name or glob pattern" >&2
            return 1
        fi
        
        return 2
    fi
    
    # Case 2: Has slashes → recursively process path components
    local first_glob="${input%%/*}"        # everything before first /
    local rest_path="${input#*/}"          # everything after first /
    
    local first_match
    first_match=$(find_first_match "$dir" "$first_glob" "$search_mode")
    
    if [[ -d "$first_match" ]]; then
        local result
        result=$(glob_with_subdir_match "$first_match" "$rest_path" "$search_mode")
        local status=$?
        
        if [[ $status -eq 0 && -n "$result" ]]; then
            echo "$result"
            return 0
        fi
    fi
    
    if [[ "$dir" == "/" ]]; then
        echo "Error: '$input' not found in any of the directories in the path. Try glob-pattern or parent_dir/child_dir pattern or verify folder name or glob pattern" >&2
        return 1
    fi
    
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
    echo "Error: '$pattern' not found in any of the directories in the path. Try regex-pattern or parent_dir/child_dir pattern or verify folder name or regex pattern" >&2
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
# find_ancestor() {
#     if [[ $# -ne 1 ]]; then
#         echo "Usage: find_ancestor <pattern>" >&2
#         echo "Example: find_ancestor 'project_root'" >&2
#         echo "Example: find_ancestor project_root/something" >&2
#         echo "Example: find_ancestor project_root/*something*" >&2
#         echo "Example: find_ancestor project_root*/*something*" >&2
#         return 1
#     fi
    
#     local ancestor_pattern="$1"
#     # local pattern="$1"
#     pattern="${ancestor_pattern%%/*}"
#     subfolder_path="${ancestor_pattern##*/}"
#     # echo "$pattern | $subfolder_path" 
#     local dir="$(pwd)"

#     while [[ "$dir" != "/" ]]; do
#         local basename="$(basename "$dir")"
#         # Support both exact match and regex pattern
#         if [[ "$basename" == $pattern ]] || [[ "$basename" =~ $pattern ]]; then
#             # echo "$dir"
#             # wnen ancestor pattern contains pattern folder_name*/folder_name*
#             new_path=$(find "$dir" -type d -name "$subfolder_path" -print -quit 2>/dev/null) 
#             # when in ancestor_pattern contains only 1 folder name instead of folder_name*/folder_name*
#             if [[ -z "$new_path" ]]; then
#                 new_path=$dir
#             fi
#             # echo "found new_path $new_path"
#             echo $new_path
#             # echo "$dir | $new_path"
#             return 0
#         fi
#         dir="$(dirname "$dir")"
#     done
#     echo "Error: Ancestor matching '$pattern' not found." >&2
#     return 1
# }

find_ancestor() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: find_ancestor <pattern>" >&2
        echo "Example: find_ancestor 'project_root'" >&2
        echo "Example: find_ancestor 'project_root/something'" >&2
        echo "Example: find_ancestor 'project_root/*something*'" >&2
        echo "Example: find_ancestor 'project_root*/*something*'" >&2
        return 1
    fi
    
    local ancestor_pattern="$1"
    local dir="$(pwd)"
    
    while [[ "$dir" != "/" ]]; do
        local basename="$(basename "$dir")"
        
        # Check if current basename matches the first component of ancestor_pattern
        local first_component="${ancestor_pattern%%/*}"
        
        # Support both exact match and glob pattern
        if [[ "$basename" == $first_component ]] || [[ "$basename" =~ $first_component ]]; then
            # Check if ancestor_pattern has subfolders (contains /)
            if [[ "$ancestor_pattern" == */* ]]; then
                # Has subfolders → use glob_with_subdir_match recursively
                local remaining_path="${ancestor_pattern#*/}"
                local result=$(glob_with_subdir_match "$dir" "$remaining_path")
                
                if [[ $? -eq 0 && -n "$result" ]]; then
                    echo "$result"
                    return 0
                fi
            else
                # No subfolders → ancestor is the current dir
                echo "$dir"
                return 0
            fi
        fi
        
        dir="$(dirname "$dir")"
    done
    
    echo "Error: Ancestor matching '$ancestor_pattern' not found." >&2
    return 1
}
# Copy using ancestor name/pattern
ancestor_based_operation() {
    local dry_run=true # by default true
    local copy_flag=false
    local move_flag=false
    local ancestor_pattern=""
    local src_name=""
    local dst_name=""
    local file_name=""

    # Determine mode label
    local mode_label=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run=true
                mode_label="[DRY-RUN]"
                shift
                ;;
            --copy)
                copy_flag=true
                shift
                ;;
            --move)
                move_flag=true
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
                    # # current folder
                    # if [[ $dst_name == "." ]]; then
                    #     dst_name=$(basename $(pwd));
                    # #  parent of current folder
                    # elif [[ $dst_name == ".." ]]; then
                    #     dst_name=$(basename $(dirname $(pwd)));
                    # # grandparent of current folder
                    # elif [[ $dst_name == "../.." ]]; then
                    #     dst_name=$(basename $(dirname $(dirname $(pwd))));
                    # fi

                    if [[ $dst_name == *"."* ]]; then

                        dst_name=$(get_folder_name_for_dots "$dst_name" ) 
                    
                        # if [[ "$dst_name" == *"Error"* ]]; then
                        #     # during error the error statement is saved in $dst_name variable so print the error
                        #     echo "$dst_name"
                        #     return 1
                        # fi
                    fi

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
    if [[ -z "$ancestor_pattern" || -z "$src_name" || -z "$dst_name" ]]; then
        echo "Usage: ancestor_based_operation [--dry-run] [--move] <ancestor_pattern> <source_folder> <dest_folder> [file_name]" >&2
        echo "--dry-run or --move or --copy flag can be put anywhere after ancestor_based_operation " >&2
        echo "by default dry_run operation runs " >&2
        echo "Example: ancestor_based_operation 'terragrunt/tutorial' compute terraform" >&2
        echo "Example: ancestor_based_operation --move  '*terragrunt/terrag*' 'terraf*' 'backen*'" >&2
        echo "Example: ancestor_based_operation --move --dry-run '*terragrunt/terrag*' 'terraform terrag*/pack*'"  >&2
        echo "Example: ancestor_based_operation  '*terragrunt/terrag*' --dry-run 'terraform --move terrag*/pack*'"  >&2
        return 1
    fi


    if [[ $copy_flag == true && $move_flag == true ]]; then
        echo "Error: Cannot set both --copy and --move flags" >&2
        return 1
    elif [[ $copy_flag == false && $move_flag == false ]]; then
        # Determine mode label    
        # if dry_run is true but mode_label not set
        # during default condition or explicitly setting --dry-run flags of no flags then set mode_label
        [[ "$dry_run" == true ]] && [[ -z $mode_label ]] && mode_label="[DRY-RUN]"


    elif [[ -z $mode_label ]] && [[ $copy_flag == true || $move_flag == true ]]; then
        echo "operation without dry run"
        # Determine operation mode
        local operation=""
        local operation_label=""
        # local operation="cp -r"
        # local operation_label="Copying"
        [[ "$copy_flag" == true ]] && operation="cp -r" && operation_label="Copying" && [[ -z $mode_label ]] && dry_run=false
        [[ "$move_flag" == true ]] && operation="mv" && operation_label="Moving" && [[ -z $mode_label ]] &&  dry_run=false
        
    else 
        # when --dry-run is set with either --move or --copy flags then set to dry-run
        [[ "$dry_run" == true ]] && [[ -z $mode_label ]] && mode_label="[DRY-RUN]"

    fi


    # # if [[ $# -ne 3 ]]; then
    # if [[ $# -gt 5 ]]; then
    #     echo "Usage: ancestor_based_operation <ancestor_pattern> <source_folder> <dest_folder> [file_name] [--dry-run]" >&2
    #     echo "Example: ancestor_based_operation 'terragrunt/tutorial' compute terraform" >&2
    #     echo "Example: ancestor_based_operation '*terragrunt/terrag*' 'terraf*' 'backen*'" >&2
    #     echo "Example: ancestor_based_operation '*terragrunt/terrag*' 'terraform terrag*/pack*'"  >&2
    #     return 1
    # fi
    
    # local ancestor_pattern="$1"
    # local src_name="$2"
    # local dst_name="$3"
    # local file_name="${4:-}"  # optional
    # local dry_run="${5:-}"

    
    echo "🔍 Finding ancestor matching: $ancestor_pattern $mode_label"
    # echo "🔍 Finding ancestor matching: $ancestor_pattern"
    local ancestor
    ancestor=$(find_ancestor "$ancestor_pattern" )
    echo "📁 Found ancestor: $ancestor"
    
    echo "🔍 Searching for source '$src_name' from ancestor..."
    local src_path
    # src_path=$(find "$ancestor" -type d -name "$src_name" -print -quit 2>/dev/null )
    src_path=$(glob_with_subdir_match "$ancestor" "$src_name" )
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
    

    if [[ -z "$dst_path" ]]; then
        # echo "Error: Destination folder '$dst_name' not found below $ancestor." >&2
        echo "Error: Destination folder '$dst_name' not found " >&2
        return 1
    fi

    echo "📁 Found destination: $dst_path"
    
    # # echo "📦 Copying from $src_path → $dst_path"
    # # cp -r "$src_path"/* "$dst_path"/

    if [[ -z "$file_name" ]]; then
        # echo "📦 Copying ALL files from $src_path → $dst_path"
        if [[ "$dry_run" == true ]]; then
            echo "it is a dry run, you get the source and destination path." 
            echo "Use flags --move or --copy to perform move or copy operation"
            return 0
        fi
        echo "📦 $operation_label ALL files from $src_path → $dst_path"
        $operation "$src_path"/* "$dst_path"/

        # cp -r "$src_path"/* "$dst_path"/
    else
        if [[ "$dry_run" == true ]]; then
            echo "it is a dry run, you get the source and destination path." 
            echo "Use flags --move or --copy to perform move or copy operation"
            return 0
        fi
        # echo "📄 Copying ONLY file '$file_name'"
        local src_file
        src_file=$(find "$src_path" -maxdepth 1 -type f -name "$file_name" -print -quit 2>/dev/null )
        # src_file=$(find "$src_path" -type f -name "$file_name" -print -quit 2>/dev/null | tee /dev/tty)

        if [[ -z "$src_file" ]]; then
            echo "Error: File '$file_name' not found inside $src_path" >&2
            return 1
        fi
      
    
        echo "📁 Found source file: $src_file"
   
        
        echo "📄 $operation_label ONLY file '$file_name'"
        $operation "$src_file" "$dst_path"/

        # cp "$src_file" "$dst_path"/
    fi

    echo "✅ Operation done."
}

get_folder_name_for_dots () {
    # only handles the paths containing "."
    local dst_name="$1"
    local target_path
    
    # Convert relative path to absolute path
    target_path=$(cd "$dst_name" 2>/dev/null && pwd)
    
    if [[ -z "$target_path" ]]; then
        # since now i am using >&2 it automatically propagates error to stderr and prints the error on the terrminal i don't nee to capture and propagate the error any other way
        echo "Error: Invalid path '$dst_name'" >&2
        return 1
    fi
    
    # Get the folder name
    basename "$target_path"
}


# move level up and go to the other specified directory from that level
level_based_operation() {
    local dry_run=true # by default true
    local copy_flag=false 
    local move_flag=false
    local up_levels=""
    local src_name=""
    local dst_name=""
    local file_name=""

    # Determine mode label
    local mode_label=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run=true
                mode_label="[DRY-RUN]"
                shift
                ;;
            --copy)
                copy_flag=true
                shift
                ;;
            --move)
                move_flag=true
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
                    
                    # # current folder
                    # if [[ $dst_name == "." ]]; then
                    #     dst_name=$(basename $(pwd));
                    # #  parent of current folder
                    # elif [[ $dst_name == ".." ]]; then
                    #     dst_name=$(basename $(dirname $(pwd)));
                    # # grandparent of current folder
                    # elif [[ $dst_name == "../.." ]]; then
                    #     dst_name=$(basename $(dirname $(dirname $(pwd))));
                    # fi
                    if [[ $dst_name == *"."* ]]; then

                        dst_name=$(get_folder_name_for_dots "$dst_name" ) 
                    
                        # if [[ "$dst_name" == *"Error"* ]]; then
                        #     # during error the error statement is saved in $dst_name variable so print the error
                        #     echo "$dst_name"
                        #     return 1
                        # fi
                    fi

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
        echo "Usage: level_based_operation [--dry-run] [--move] <up_levels> <source_folder> <dest_folder> [file_name]" >&2
        echo "--dry-run or --move or --copy flag can be put anywhere after level_based_operation " >&2
        echo "by default dry-run operation runs " >&2
        echo "Example: level_based_operation 3 templates config" >&2
        echo "Example: level_based_operation --move --dry-run 3 templates config config.sh" >&2
        echo "Example: level_based_operation --move  3 templa* conf* conf*.sh" >&2
        echo "Example: level_based_operation  3 templa* --move conf* conf*.sh" >&2
        echo "Example: level_based_operation  3 templa*  conf* --dry-run conf*.sh" >&2
        return 1
    fi

    # Validate that up_levels is a number
    if ! [[ "$up_levels" =~ ^[0-9]+$ ]]; then
        echo "Error: First argument must be a number (levels to go up)." >&2
        echo "Usage: level_based_operation <up_levels> <source_folder> <dest_folder>" >&2
        return 1
    fi

    if [[ $copy_flag == true && $move_flag == true ]]; then
        echo "Error: Cannot set both --copy and --move flags" >&2
        return 1
    elif [[ $copy_flag == false && $move_flag == false ]]; then
        # Determine mode label    
        # if dry_run is true but mode_label not set
        # during default condition or explicitly setting --dry-run flags of no flags then set mode_label
        [[ "$dry_run" == true ]] && [[ -z $mode_label ]] && mode_label="[DRY-RUN]"


    elif [[ -z $mode_label ]] && [[ $copy_flag == true || $move_flag == true ]]; then
        echo "operation without dry run"
        # Determine operation mode
        local operation=""
        local operation_label=""
        # local operation="cp -r"
        # local operation_label="Copying"
        [[ "$copy_flag" == true ]] && operation="cp -r" && operation_label="Copying" && [[ -z $mode_label ]] && dry_run=false
        [[ "$move_flag" == true ]] && operation="mv" && operation_label="Moving" && [[ -z $mode_label ]] &&  dry_run=false
        
    else 
        # when --dry-run is set with either --move or --copy flags then set to dry-run
        [[ "$dry_run" == true ]] && [[ -z $mode_label ]] && mode_label="[DRY-RUN]"

    fi



    # # Determine operation mode
    # local operation=""
    # local operation_label=""
    # # local operation="cp -r"
    # # local operation_label="Copying"
    # [[ "$copy_flag" == true ]] && operation="cp -r" && operation_label="Copying"
    # [[ "$move_flag" == true ]] && copy_flag=false && operation="mv" && operation_label="Moving" 

    # # Determine mode label
    # local mode_label=""
    # [[ "$dry_run" == true ]] && mode_label="[DRY-RUN]"

        
    # # if [[ $# -ne 3 ]]; then
    # if [[ $# -gt 4 || $# -lt 3 ]]; then
    #     echo "Usage: level_based_operation <up_levels> <source_folder> <dest_folder> [file_name]" >&2
    #     echo "Example: level_based_operation 3 templates config " >&2
    #     echo "Example: level_based_operation 3 templates config config.sh" >&2
    #     return 1
    # fi
    
    # local up_levels="$1"
    # local src_name="$2"
    # local dst_name="$3"
    # local file_name="${4:-}"  # optional
    
    # Validate that up_levels is a number
    # if ! [[ "$up_levels" =~ ^[0-9]+$ ]]; then
    #     echo "Error: First argument must be a number (levels to go up)." >&2
    #     echo "Usage: level_based_operation <up_levels> <source_folder> <dest_folder>" >&2
    #     return 1
    # fi
    
    echo "🔍 Going up $up_levels level(s), then searching for '$src_name'... $mode_label"
    # echo "🔍 Going up $up_levels level(s), then searching for '$src_name'..."
    src_path=$(go_up_then_down "$up_levels" "$src_name" )
    # src_path=$(go_up_then_down "$up_levels" "$src_name" | tee /dev/tty)
    echo "📁 Found source: $src_path"
    
    echo "🔍 Searching for destination '$dst_name' upward from current location..."
    dst_path=$(go_up_until "$dst_name")
    # dst_path=$(go_up_until "$dst_name" | tee /dev/tty)
    
     if [[ -z "$dst_path" ]]; then
        # echo "Error: Destination folder '$dst_name' not found below $ancestor." >&2
        echo "Error: Destination folder '$dst_name' not found " >&2
        return 1
    fi
    
    echo "📁 Found destination: $dst_path"
   

    # echo "📦 Copying from $src_path → $dst_path"
    # cp -r "$src_path"/* "$dst_path"/
    # cp "$src_path_file" "$dst_path"/

   if [[ -z "$file_name" ]]; then
        # echo "📦 Copying ALL files from $src_path → $dst_path"
        if [[ "$dry_run" == true ]]; then
            echo "it is a dry run, you get the source and destination path." 
            echo "Use flags --move or --copy to perform move or copy operation"
            return 0
        fi
        echo "📦 $operation_label ALL files from $src_path → $dst_path"
        $operation "$src_path"/* "$dst_path"/

    else
        
        if [[ "$dry_run" == true ]]; then
            echo "it is a dry run, you get the source and destination path." 
            echo "Use flags --move or --copy to perform move or copy operation"
            return 0
        fi
        # echo "📄 Copying ONLY file '$file_name'"
        local src_file
        src_file=$(find "$src_path" -maxdepth 1 -type f -name "$file_name" -print -quit)

        if [[ -z "$src_file" ]]; then
            echo "Error: File '$file_name' not found inside $src_path" >&2
            return 1
        fi
        
        echo "📄 $operation_label ONLY file '$file_name'"
        $operation "$src_file" "$dst_path"/

        # cp "$src_file" "$dst_path"/
    fi

    echo "✅ Operation done."
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
interactive_operation() {
    
    echo "🔍 Available ancestors:"
    list_ancestors
    echo ""
    read -p "Enter ancestor level number or name/pattern: " input
    read -p "source folder name: " src_name
    read -p "Enter destination folder name: " dst_name
    read -p "Enter file name to copy from source to destination: " file_name
    read -p "Enter operation flag --dry-run or --move or --copy : " operation
    
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
        # nth_ancestor_based_operation "$input" "$src_name" "$dst_name"
        level_based_operation "$input" "$src_name" "$dst_name" "$file_name" "$operation"
    else
        ancestor_based_operation "$input" "$src_name" "$dst_name" "$file_name" "$operation"
    fi
}

# Help function
show_help() {
    cat << 'EOF'
📚 Directory Navigation & Copy Tool

USAGE: ./ancestor.sh [OPTIONS] <command> [arguments...]

OPTIONS:
  -h, --help, --show_help    Show this help message

========================================================================
🛠️  OPERATIONAL MODES (For Copy & Move Commands)
========================================================================
The copy commands (ancestor_based_operation, level_based_operation) operate in 
SAFE MODE by default.

  --dry-run   (Default) Simulates the operation without making changes.
              Prints source/destination paths and the command that would run.
  --copy      Executes a live copy (cp -r).
  --move      Executes a live move (mv).

  * Note: Flags can be placed anywhere in the argument list.
  * Note: You cannot use --copy and --move together.
========================================================================

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

5. ancestor_based_operation [FLAGS] <ancestor_pattern> <src> <dst> [file_name]
   folder_name(glob-pattern) or folder_name(glob-pattern)/folder_name(glob-pattern) use 1 or multiple levels in <ancestor_pattern> <src> <dst>
  
   Finds ancestor, searches src downwards, searches dst upwards.
   
   ⚠️  DEFAULT: DRY-RUN (No changes made)

   Copy or move files using ancestor pattern to locate source and destination
   - Finds ancestor matching the pattern
   - Searches downward from ancestor for source folder
   - Searches upward from current location for destination folder
   - Copies  or moves specific folder
   - Optionally copies or moves only a specific file

   
   Use Cases:
   [Simulation / Safe Check]
     ./ancestor.sh ancestor_based_operation 'project_root' templates config
     ./ancestor.sh ancestor_based_operation --dry-run 'project_root' templates config

   [Live Copy Action]
     ./ancestor.sh ancestor_based_operation --copy 'project_root' templates config --copy
     ./ancestor.sh ancestor_based_operation --copy 'arch*' src build main.tf --copy
     ./ancestor.sh ancestor_based_operation '*terragrunt' terrag*/roo*/scri* *https/terraf*/compute --copy


   [Live Move Action]
     ./ancestor.sh ancestor_based_operation --move 'project_root' old_folder new_folder
     ./ancestor.sh ancestor_based_operation 'project_root' old_folder new_folder --move
     ./ancestor.sh ancestor_based_operation '*terragrunt/' terrag*/roo*/scri* *https/terraf*/compute  --move


   [Complex Patterns]
     ./ancestor.sh ancestor_based_operation --copy 'arch*/three*' 'terra*' 'backend*'
     ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform 'lirw-terragr*/terraf*'
     ./ancestor.sh ancestor_based_operation '*terragrunt' terrag*/roo*/scri* *https/terraf*/compute 
     ./ancestor.sh ancestor_based_operation '*arch/*tier*terragrunt' terrag*/roo*/scri* *https/terraf*/compute --dry-run 
      ./ancestor.sh ancestor_based_operation 'scr*/*arch/*tier*terragrunt' terrag*/roo*/scri* *https/terraf*/compute --dry-run

6. level_based_operation [FLAGS] <up_levels> <src> <dst> [file_name]
   Goes up N levels, searches src downwards, searches dst upwards.
   
   ⚠️  DEFAULT: DRY-RUN (No changes made)

   Go up N levels, find source folder downward, find destination upward
   - Goes up specified number of levels from current directory
   - Searches downward from that point for source folder
   - Searches upward from current location for destination folder
   - Copies or moves specific folder
   - Optionally copies or moves only a specific file

   Use Cases:
   [Simulation / Safe Check]
     ./ancestor.sh level_based_operation 3 templates config
     ./ancestor.sh level_based_operation 3 templates config --dry-run

   [Live Copy Action]
     ./ancestor.sh level_based_operation --copy 4 terraform lirw-terragrunt/terraform
     ./ancestor.sh level_based_operation 4 terraform terraf* --copy

   [Live Move Action]
     ./ancestor.sh level_based_operation --move 2 temp_data final_data
     ./ancestor.sh level_based_operation --move 2 'temp*' 'final*' data.json
     ./ancestor.sh level_based_operation --move 2 'temp*' 'final*' da*.json

7. interactive_operation
   Interactive mode - shows ancestor list and prompts for all inputs
   - Lists all ancestors with level numbers
   - Prompts for ancestor level/pattern, source folder, destination folder, optional file name and operation to run
   - Automatically determines whether to use level-based or pattern-based copy
   
   Usage: ./ancestor.sh interactive_operation

GLOB PATTERN EXAMPLES:
  *              Matches any characters
  ?              Matches single character
  project*       Matches: project, project-main, project123
  *config*       Matches: myconfig, config-prod, old-config-backup
  proj???        Matches: project, proj123 (exactly 3 chars after proj)
  parent*/child  Matches: parent-a/child, parent-xyz/child

SOURCING THE SCRIPT:
  You can source this script and call functions directly in your shell:
  
  source ./ancestor.sh
  list_ancestors
  go_up_until 'config'
  ancestor_based_operation 'myproject' src build
  level_based_operation 3 templates config main.tf
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
        ancestor_based_operation)
            shift
            ancestor_based_operation "$@"
            ;;
        level_based_operation)
            shift
            level_based_operation "$@"
            ;;
        interactive_operation)
            shift
            interactive_operation "$@"
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



# ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform lirw-terragr*/terraf* main.tf
# ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform lirw-terragr*/terraf* 
# ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform terraf* 
# ./ancestor.sh ancestor_based_operation arch*/three*archi*retry terraform terraf* 
# ./ancestor.sh ancestor_based_operation arch/three*archi*retry terraform terraf* 
# ./ancestor.sh ancestor_based_operation arch/*retry terraform terraf* 


# for regex matching
# ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform "lirw-terragr[^/]+/terraf[^/]+"
# ./ancestor.sh ancestor_based_operation 'arch*/three*archi*retry' terraform lirw-terragr[^/]+/terraf[^/]+



# ./ancestor.sh ancestor_based_operation '*terragrunt/terrag*' scri* modu*/scri* 
#  ./ancestor.sh ancestor_based_operation '*terragrunt/terrag*' roo*/scri* modules/compute


# ./ancestor.sh ancestor_based_operation '*terragrunt/' terrag*/roo*/scri* *https/terraf*/compute --dry-run 
# ./ancestor.sh ancestor_based_operation '*arch/*tier*terragrunt' terrag*/roo*/scri* *https/terraf*/compute 


#  ./ancestor.sh ancestor_based_operation 'scr*/*arch/*tier*terragrunt' terrag*/roo*/scri* *https/terraf*/compute --dry-run