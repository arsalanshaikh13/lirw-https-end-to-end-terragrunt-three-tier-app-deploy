#!/bin/bash
set -xeuo pipefail  # Exit on any error
echo "${environment_stage}: environment variable"
# ansible-playbook ../../../../../packer/packer-ansible.yml -vvvv 2>&1 | tee -a ../../../../../packer/ansible_output.log
ansible-playbook "${packer_folder}/packer-ansible.yml" -vvvv 2>&1 | tee -a "${packer_folder}/ansible_output.log"
exit_code=${PIPESTATUS[0]}
if [ $$exit_code -ne 0 ]; then
    echo "❌ Ansible playbook failed with exit code $exit_code"
    exit $exit_code
fi
echo "✅ Ansible playbook completed successfully"