#!/usr/bin/env bash

# # ./startup.sh 2>&1 | tee >(sed 's/\x1b\[[0-9;]*m//g' > logs/setupnew1.log )

set -euo pipefail
operation=$1
if [ $operation == "startup" ]; then
    file_name="startup-log"
elif [ $operation == "cleanup" ]; then
    file_name="cleanup-log"
fi

file_name="${1:-startup-up-log}"

echo "filename : $file_name"
LOG_DIR="root/logs"
mkdir -p "$LOG_DIR"

# Find the highest existing numbered log file (filename only), sorted versionally
last_file=$(find "$LOG_DIR" -maxdepth 1 -type f -name "${file_name}*.log" -printf '%f\n' 2>/dev/null | sort -V | tail -n1 || true)
# last_file=$(ls "$LOG_DIR"/startup-up*.log 2>/dev/null | sort -V | tail -n 1 || true)
echo "last file: $last_file"
if [ -z "$last_file" ]; then
  next_num=0
else
  last_num=$(basename "$last_file" .log | grep -oE '[0-9]+$' || echo 0)
  echo "last num : $last_num"
  next_num=$((last_num + 1))
fi

LOG_FILE="$LOG_DIR/startup-up-log${next_num}.log"
echo "Logging terragrunt output to: $LOG_FILE"

# Run terragrunt, remove ANSI color codes and tee to console + logfile
# Note: use double-quoted "$LOG_FILE" in the process substitution to be safe
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all -- apply --parallelism 50 2>&1 \
#   | tee >(sed -E 's/\x1b\[[0-9;]*m//g' > "$LOG_FILE")

# {
#   echo "===== Terragrunt Apply Started at $(date) ====="
#   TERRAGRUNT_DISABLE_COLORS=true TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all -- apply --parallelism 50
#   echo "===== Terragrunt Apply Finished at $(date) ====="
# } 2>&1 | tee >(sed -E 's/\x1b\[[0-9;]*m//g' > "$LOG_FILE" )  # tee "$LOG_FILE"

# Trap function to handle interruption
cleanup() {
  echo ""
  echo "Script interrupted. Processing log file..."
  # # Strip ANSI codes from the log file
  if [ -f "$LOG_FILE.tmp" ]; then
    sed -E 's/\x1b\[[0-9;]*m//g' "$LOG_FILE.tmp" > "$LOG_FILE"
    rm "$LOG_FILE.tmp"
    echo "Log file saved to: $LOG_FILE"
  fi
#   exit 130
#     echo "running cleanup"
}

# handle_interrupt() {
#   echo ""
#   echo "⚠️  Script interrupted by user"
#   exit 130
# }
# # Set up trap for SIGINT (Ctrl+C) and SIGTERM
# trap cleanup EXIT
# trap handle_interrupt INT TERM ERR


handle_interrupt() {
  # capture the error code the first thing in the program
  echo " error code : $?"
  local signal=$1

  echo "detecting reasons for interruption in the program"
  
  case "$signal" in
    INT)
      echo "⚠️  Script interrupted by user (Ctrl+C)"
      exit 130
      ;;
    TERM)
      echo "⚠️  Script terminated by signal"
      exit 143
      ;;
    ERR)
      echo "❌ Script failed due to error"
      exit 1
      ;;
    *)
      echo "⚠️  Script interrupted"
      exit 1
      ;;
  esac
}

# Set up traps - pass signal name to handler
# cleanup always run on error or successful completion of the script
trap cleanup EXIT 
trap 'handle_interrupt INT' INT
trap 'handle_interrupt TERM' TERM
trap 'handle_interrupt ERR' ERR

if [ $operation == "startup" ]; then
    file_name="startup-log"
  {
    echo "===== Terragrunt Apply Started at $(date) ====="
  #   exit 2
    TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all -- apply --parallelism 50
    echo "===== Terragrunt Apply Finished at $(date) ====="
  } 2>&1 | tee "$LOG_FILE.tmp"

elif [ $operation == "cleanup" ]; then
    file_name="cleanup-log"
fi
# {
#   echo "===== Terragrunt Apply Started at $(date) ====="
# #   exit 2
#   TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all -- apply --parallelism 50
#   echo "===== Terragrunt Apply Finished at $(date) ====="
# } 2>&1 | tee "$LOG_FILE.tmp"

# # Strip ANSI codes from the log file
# this is handled inside cleanup
# sed -E 's/\x1b\[[0-9;]*m//g' "$LOG_FILE.tmp" > "$LOG_FILE"
# rm -f "$LOG_FILE.tmp"

# Capture exit code of the pipeline's leftmost command (terragrunt)
# terragrunt_rc=${PIPESTATUS[0]:-0}

# if [ "$terragrunt_rc" -ne 0 ]; then
#   echo "Terragrunt exited with code $terragrunt_rc (see $LOG_FILE for details)"
#   exit "$terragrunt_rc"
# else
#   echo "Terragrunt completed successfully — output saved to $LOG_FILE"
# fi

echo "Terragrunt completed successfully — output saved to $LOG_FILE"

# echo "exiting after trap cleanup EXIT"s



echo "Found all 3 .pub files ✔"


check_local_keys() {
    local key_name=$1
    [ -f "$key_name" ] && [ -f "$key_name.pub" ]
    return $?
}
check_total_keys() {
  mapfile -t keys < <(find . -maxdepth 1 -type f -name "*.pub")

count="${#keys[@]}"

if [ "$count" -eq 3 ]; then
  echo "✔ All 3 keys are present:"
  printf ' - %s\n' "${keys[@]}"
  exit 0
fi

echo "❌ Error: Expected 3 keys, found $count"
printf ' - %s\n' "${keys[@]}"
exit 1

}

make_ssh_keys(){
cd modules/nat_key
mkdir -p key
cd key

check_total_keys

if ! check_local_keys "nat-bastion"; then
    echo "Creating backend key pair..."
    ssh-keygen -t rsa -b 4096 -f nat-bastion -N ""
else
    echo "nat-bastion key pair already exists locally"
fi
echo "nat-bastion SSH key pairs setup completed"

# Generate frontend key pair if it doesn't exist
if ! check_local_keys "client_key"; then
    echo "Creating client key pair..."
    ssh-keygen -t rsa -b 4096 -f client_key -N ""
else
    echo "Client key pair already exists locally"
fi

if ! check_local_keys "server_key"; then
    echo "Creating server key pair..."
    ssh-keygen -t rsa -b 4096 -f server_key -N ""
else
    echo "Server key pair already exists locally"
fi

echo "SSH key pairs setup completed"
}
make_ssh_keys
