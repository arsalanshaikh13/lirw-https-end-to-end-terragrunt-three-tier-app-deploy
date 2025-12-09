#!/bin/bash

set -euo pipefail
# operation=${1:-startup}  # Default to startup if no arg

# CACHE_DIR="backend-tfstate-bootstrap/.terragrunt-cache"


# if [ ! -d $CACHE_DIR ]; then

#   echo "❌ Backend state file not found. Running backend setup..."
#   TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --working-dir backend-tfstate-bootstrap -- apply -auto-approve --parallelism 50 
#   exit 0
# fi

# echo "Checking backend infrastructure... inside: $CACHE_DIR"

# # Look for terraform.tfstate in backend directory
# # find returns 1 when it doen't finds any file or directory which make set -e to stop immediately on any non-0 return values
# BACKEND_STATE=$(find backend-tfstate-bootstrap/.terragrunt-cache -type f -name "terraform.tfstate" 2>/dev/null | head -n 1)
# echo "$BACKEND_STATE"
# if [ -z "$BACKEND_STATE" ]; then
#   if [ "$operation" = "cleanup" ]; then
#     echo "❌ Error: Backend infrastructure does not exist. Cannot perform cleanup."
#     exit 1
#   fi
#   echo "❌ Backend state file not found. Running backend setup..."
#   TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --working-dir backend-tfstate-bootstrap -- apply -auto-approve --parallelism 50
#   # exit 0

# # elif ! grep -qE '"arn:aws:[^"]+"|"id":\s*"[^"]+"' "$BACKEND_STATE"; then
# elif  grep -q '"resources": *\[\]' "$BACKEND_STATE"; then

#   if [ "$operation" = "cleanup" ]; then
#     echo "❌ Error: Backend infrastructure does not exist. Cannot perform cleanup."
#     exit 1
#   fi
#   echo "⚠️  Backend state file exists but appears empty. Running backend setup..."
#   TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --working-dir backend-tfstate-bootstrap -- apply  -auto-approve --parallelism 50
#   # exit 0

# else
#   echo "✅ Backend infrastructure exists (resources is not empty)"
#   # exit 0
# fi


# # If cache folder does NOT exist → run apply immediately
# if [[ ! -d "$CACHE_DIR" ]]; then
#   echo "⚠️  Cache directory does not exist."
#   echo "🛠  Running Terragrunt apply to initialize backend..."
#   TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --working-dir backend-tfstate-bootstrap -- apply --parallelism 50
#   exit 0
# fi

# # Find terraform.tfstate inside nested terragrunt-cache directories
# STATE_FILE=$(find "$CACHE_DIR" -type f -name "terraform.tfstate" | head -n 1)

# if [[ -z "$STATE_FILE" ]]; then
#   echo "⚠️  No terraform.tfstate found inside cache!"
#   echo "🛠  Running Terragrunt apply..."
#   TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --working-dir backend-tfstate-bootstrap -- apply --parallelism 50
#   exit 0
# fi

# echo "📄 Found terraform.tfstate: $STATE_FILE"
# echo "Checking its contents..."

# # Check if resources array is empty
# if grep -q '"resources": \[\]' "$STATE_FILE"; then
#   echo "🚨 State file contains NO resources. Need to create backend."
#   TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --working-dir backend-tfstate-bootstrap -- apply --parallelism 50
# else
#   echo "✅ State file contains resources. Backend already initialized."
# fi



operation=${1:-startup}  # Default to startup if no arg
ENVIRONMENTS=("dev" "prod")
# ENVIRONMENTS=("dev")

# Function to check if backend has resources
check_backend_state() {
  local env=$1
  pwd
  CACHE_DIR="backend-tfstate-bootstrap/$env/.terragrunt-cache"


  if [ ! -d $CACHE_DIR ]; then

    echo "❌ Backend state file not found. Running backend setup..."
    return 1
  fi

  local STATE_FILE=$(find backend-tfstate-bootstrap/$env/.terragrunt-cache -type f -name "terraform.tfstate" 2>/dev/null | head -n 1 )
  if [ -z "$STATE_FILE" ]; then
    echo "⚠️  ${env}: State file not found" >&2
    return 1
  elif grep -q '"resources": *\[\]' "$STATE_FILE"; then
    echo "⚠️  ${env}: State file exists but empty" >&2
    return 1
  else
    echo "✅ ${env}: Backend infrastructure exists"
    return 0
  fi
}

# Function to setup backend for an environment
setup_backend() {
  local env=$1
  echo "🚀 Setting up ${env} backend..."
  TG_PROVIDER_CACHE=1 terragrunt run --non-interactive \
    --working-dir "backend-tfstate-bootstrap/${env}" \
    -- apply -auto-approve --parallelism 50
  # TG_PROVIDER_CACHE=1 terragrunt run --non-interactive \
  #   --working-dir "backend-tfstate-bootstrap/${env}" \
  #   -- plan --parallelism 50
}

# Main logic
echo "Checking backend infrastructure..."

for env in "${ENVIRONMENTS[@]}"; do
  if ! check_backend_state "$env"; then
    if [ "$operation" = "cleanup" ]; then
      echo "❌ Error: ${env} backend infrastructure missing. Cannot perform cleanup." >&2
      exit 1
    fi
    setup_backend "$env"
  fi
done

echo "✅ All backend infrastructures are ready"