#!/bin/bash
set -xeuo pipefail  # Exit on any error
echo "${environment_stage}: environment variable"
LOG_DIR="${packer_folder}/ansible-logs"
mkdir -p "$LOG_DIR"

# Find the highest existing number
last_log=$(ls "$LOG_DIR"/*.log 2>/dev/null | sort -V | tail -n 1 || true)
if [ -z "$last_log" ]; then
    next_num=0
else
    last_num=$(basename "$last_log" .log | grep -oE '[0-9]+$' || echo 0)
    next_num=$((last_num + 1))
fi

LOG_FILE="$LOG_DIR/ansible_output-${environment_stage}-${next_num}.log"
# ansible-playbook ../../../../../packer/packer-ansible.yml -vvvv 2>&1 | tee -a ../../../../../packer/ansible_output.log
# ansible-playbook "${packer_folder}/packer-ansible.yml" -vvvv 2>&1 | tee -a "${packer_folder}/ansible_output.log"
ansible-playbook "${packer_folder}/packer-ansible.yml" -vvvv 2>&1 | tee -a "$LOG_FILE.tmp"
echo ""
echo "Processing log file..."
if [ -f "$LOG_FILE.tmp" ]; then
    sed -E 's/\x1b\[[0-9;]*m//g' "$LOG_FILE.tmp" > "$LOG_FILE"
    rm "$LOG_FILE.tmp"
    echo "Log file saved to: $LOG_FILE"
fi
exit_code=${PIPESTATUS[0]}
if [ $$exit_code -ne 0 ]; then
    echo "❌ Ansible playbook failed with exit code $exit_code"
    exit $exit_code
fi
echo "✅ Ansible playbook completed successfully"