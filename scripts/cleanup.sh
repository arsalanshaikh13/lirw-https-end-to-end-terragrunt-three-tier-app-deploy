#!/bin/bash
set -euo pipefail


# # destroy_order=("hosting" "compute" "database" "nat_key"  "permissions" "network" "s3" )
# destroy_order=("hosting/route53" "hosting/cloudfront" "compute/asg"
#                "compute/null_resource" "compute/alb" "database/aws_secret"
#                "database/rds" "nat_instance" "s3" "permissions/acm" 
#                "permissions/iam_role" "network/security-group" "network/vpc" )

# echo "🔥 Destroying Terraform stacks in reverse dependency order..."

# for dir in "${destroy_order[@]}"; do
#   echo "🧨 Destroying ${dir}..."
#   # cd $dir
#   # TG_PROVIDER_CACHE=1 terragrunt run --non-interactive  --all  -- destroy -auto-approve -lock=false --parallelism 20   || true
#   TG_PROVIDER_CACHE=1 terragrunt run --non-interactive  --working-dir $dir   -- destroy -auto-approve  --parallelism 20   || true
#   # TG_PROVIDER_CACHE=1 terragrunt run --non-interactive  --working-dir hosting/route53  -- destroy -auto-approve -lock=false --parallelism 20   || true
#   # cd ..
# done

# echo "✅ All stacks destroyed successfully."

# Folders that should be destroyed in parallel
parallel_destroy_zero=(
  "terraform/hosting/route53"
  "terraform/hosting/cloudfront"  
)


echo "🔥 Destroying selected Terraform stacks in parallel..."

# ---- PARALLEL BLOCK ----
for dir in "${parallel_destroy_zero[@]}"; do
  echo "🚀 Starting destroy in background: $dir"

  TG_PROVIDER_CACHE=1 terragrunt run \
    --non-interactive \
    --working-dir "$dir" \
    -- destroy -auto-approve --parallelism 20 || true &

done

echo "⏳ Waiting for parallel tasks to complete..."
wait
echo "✅ parallel destroy completed."

parallel_destroy_one=(
  "terraform/hosting/waf"
  "terraform/compute/alarm"  

)
  # "terraform/nat_key/nat_instance" 
echo "🔥 Destroying selected Terraform stacks in parallel..."

# ---- PARALLEL BLOCK ----
for dir in "${parallel_destroy_one[@]}"; do
  echo "🚀 Starting destroy in background: $dir"

  TG_PROVIDER_CACHE=1 terragrunt run \
    --non-interactive \
    --working-dir "$dir" \
    -- destroy -auto-approve --parallelism 20 || true &

done

echo "⏳ Waiting for parallel tasks to complete..."
wait
echo "✅ Parallel destroy completed."

# ---- SEQUENTIAL BLOCK ----
# compute folders destroyed in order (sequential)
sequential_destroy_two=(
  "terraform/compute/asg"
  "terraform/compute/ami" 
  "terraform/compute/alb" 
  "terraform/database/ssm_prm"

)
  # "terraform/nat_key/nat_instance" 
  # "compute/null_resource" 

echo "🔥 Destroying compute stacks sequentially..."

for dir in "${sequential_destroy_two[@]}"; do
  echo "🧨 Destroying $dir..."
  
  TG_PROVIDER_CACHE=1 terragrunt run \
    --non-interactive \
    --working-dir "$dir" \
    -- destroy -auto-approve --parallelism 20 || true
done


echo "⏳ Waiting for sequential tasks to complete..."
wait
echo "✅ sequential destroy completed."

parallel_destroy_two=(
  "terraform/compute/vpc_endpoint"
  "terraform/database/rds"
  "terraform/nat_key/key" 
  "terraform/s3"
  "terraform/permissions/acm" 
  "terraform/permissions/iam_role"
  "terraform/permissions/f_log"
)
  # "terraform/nat_key/nat" 
  # "terraform/nat_key/nat_instance" 
  # "terraform/database/aws_secret"
  # "terraform/permissions/vpc_flow_logs"

echo "🔥 Destroying selected Terraform stacks in parallel..."

# ---- PARALLEL BLOCK ----
for dir in "${parallel_destroy_two[@]}"; do
  echo "🚀 Starting destroy in background: $dir"

  TG_PROVIDER_CACHE=1 terragrunt run \
    --non-interactive \
    --working-dir "$dir" \
    -- destroy -auto-approve --parallelism 20 || true &

done



echo "⏳ Waiting for parallel destroy two tasks to complete..."
wait
echo "✅ parallel destroy two completed."

sequential_destroy_three=(
      "terraform/network/sg" 
      "terraform/network/vpc"
  )
      # "terraform/network/security-group" 

# ---- SEQUENTIAL BLOCK ----
echo "🔥 Destroying remaining stacks sequentially..."

for dir in "${sequential_destroy_three[@]}"; do
  echo "🧨 Destroying $dir..."
  
  TG_PROVIDER_CACHE=1 terragrunt run \
    --non-interactive \
    --working-dir "$dir" \
    -- destroy -auto-approve --parallelism 20 || true
done


echo "🎉 All stacks destroyed successfully!"

echo "🎉 destroying  tfstate backend s3 and dynamodb table!"

  TG_PROVIDER_CACHE=1 terragrunt run \
    --non-interactive \
    --working-dir backend-tfstate-bootstrap \
    -- destroy -auto-approve --parallelism 20 || true

echo "🎉 tfstate backend s3 and dynamodb table destroyed successfully  from s3!"
