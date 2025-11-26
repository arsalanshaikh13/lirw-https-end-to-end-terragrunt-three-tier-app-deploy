# Assume 'input' holds a glob pattern, like "*.txt"
# input="fi*.txt"
# base="file1.txt"

# if [[ "$base" == $input ]]; then
#     echo "Match found!"
# else
#     echo "No match."
# fi
input="lirw-terragrunt*/script*"
base="scripts"

if [[ "$base" == $input ]]; then
    echo "Match found!"
else
    echo "No match."
fi
