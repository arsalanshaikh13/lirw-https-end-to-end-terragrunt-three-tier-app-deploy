#!/bin/bash
set -euo pipefail

commit_push() {
    branch=${2:-main}
    git add --all;
    git commit -m $1;
    # git push origin $branch;
}

delete_tag() {
  local tag_name
  tag_name=$(git describe --tags)

  echo "Deleting tag: $tag_name"
  git tag -d "$tag_name"
  git push origin ":refs/tags/$tag_name"
}

create_tag() {
  local tag_name="$1"
  local message="$2"

  if [[ -z "$tag_name" ]]; then
    echo "Error: tag name is required"
    exit 1
  fi

  git tag -a "$tag_name" -m "Tagging version $tag_name: $message"
  git push origin "$tag_name"
}

case "$1" in
  delete_tag)
    delete_tag
    ;;
  create_tag)
    shift        # remove 'create'
    create_tag "$@"
    ;;
  commit_push)
    shift        # remove 'create'
    commit_push $@
    ;;
  *)
    echo "Usage:"
    echo "  ./git.sh create <tag_name> <message>"
    echo "  ./git.sh delete"
    echo "  ./git.sh commit_push <commit-message>"
    exit 1
    ;;
esac
