#!/bin/bash
set -euo pipefail
terragrunt_destroy() {
  local dir="$1"
  echo "Destroying resources in: $dir"

  TG_PROVIDER_CACHE=1 terragrunt run \
      --non-interactive \
      --working-dir "$dir" \
      -- destroy -auto-approve --parallelism 20 || true
}
destroy() {
  cd $1
  echo "🧹 Starting Terraform cleanup process..."
  # Folders that should be destroyed in parallel
  sequential_destroy_zero=(
    "hosting/route53"
    "hosting/cloudfront"  
  )

  echo "🔥 Destroying selected Terraform stacks in sequence..."

  # ---- PARALLEL BLOCK ----
  for dir in "${sequential_destroy_zero[@]}"; do
    echo "🚀 Starting destroy in background: $dir"
    terragrunt_destroy "$dir"
      # -- destroy -auto-approve --parallelism 20 || true 

  done

  echo "⏳ Waiting for sequential tasks to complete..."
  wait
  echo "✅ sequential destroy completed."


  parallel_destroy_zero=(
    "hosting/waf"
    "compute/alarm"  

  )
    # "terraform/nat_key/nat_instance" 
  echo "🔥 Destroying selected Terraform stacks in parallel..."

  # ---- PARALLEL BLOCK ----
  for dir in "${parallel_destroy_zero[@]}"; do
    echo "🚀 Starting destroy in background: $dir"

    terragrunt_destroy "$dir" &

  done

  echo "⏳ Waiting for parallel tasks to complete..."
  wait
  echo "✅ Parallel destroy completed."

# ---- SEQUENTIAL BLOCK ----
# compute folders destroyed in order (sequential)
sequential_destroy_two=(
  "compute/asg"
  "compute/ami" 
  "compute/alb" 

)

echo "🔥 Destroying compute stacks sequentially..."

for dir in "${sequential_destroy_two[@]}"; do
  echo "🧨 Destroying $dir..."
  terragrunt_destroy "$dir"

done


echo "⏳ Waiting for sequential tasks to complete..."
wait
echo "✅ sequential destroy completed."


  parallel_destroy_two=(
  "compute/vpc_endpoint"
  "database/ssm_prm"
  "database/rds"
  "nat_key/key" 
  "s3"
  "permissions/acm" 
  "permissions/iam_role"
  "permissions/f_log"
)
  # "nat_key/nat" 
  # "nat_key/nat_instance" 
  # "database/aws_secret"
  # "permissions/vpc_flow_logs"

  echo "🔥 Destroying selected Terraform stacks in parallel..."

  # ---- PARALLEL BLOCK ----
  for dir in "${parallel_destroy_two[@]}"; do
    echo "🚀 Starting destroy in background: $dir"
    terragrunt_destroy "$dir" &
  done



  echo "⏳ Waiting for parallel destroy two tasks to complete..."
  wait
  echo "✅ parallel destroy two completed."

  sequential_destroy_three=(
    "network/security-group" 
    "network/vpc"
  )

  # ---- SEQUENTIAL BLOCK ----
  echo "🔥 Destroying remaining stacks sequentially..."

  for dir in "${sequential_destroy_three[@]}"; do
    echo "🧨 Destroying $dir..."
    
    terragrunt_destroy "$dir"

  done


  echo "🎉 All stacks destroyed successfully!"
  cd ..
}
# env_folder=("terraform_dev" "terraform_prod" )
env_folder=("terraform")

for dir in ${env_folder[@]}; do
  destroy $dir
done

echo "🎉 destroying  tfstate backend s3 and dynamodb table!"

backend="backend-tfstate-bootstrap"

# Loop over each environment inside backend folder
for dir in "$backend"/*; do
  
  terragrunt_destroy "$dir" &

# done
echo "⏳ Waiting for tfstate backend s3 and dynamodb table to be destroyed..."
wait
echo "🎉 tfstate backend s3 and dynamodb table destroyed successfully  from s3!"

echo "removing terragrunt cache directories..."
find . -type d -name ".terragrunt-cache" -prune -print -exec rm -rf {} \;
find . -type f -name ".terraform.lock.hcl" -prune -print -exec rm -f {} \;
echo "✅ terragrunt cache directories removed."
