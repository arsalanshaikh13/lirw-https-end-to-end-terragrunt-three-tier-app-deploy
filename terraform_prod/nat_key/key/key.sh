#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Checks whether both private & public key files exist
# ---------------------------------------------------------------------------
check_local_key() {
    local key="$1"
    [[ -f "$key" && -f "$key.pub" ]]
}

# ---------------------------------------------------------------------------
# Generates a key pair if missing
# ---------------------------------------------------------------------------
generate_key_if_missing() {
    local key="$1"

    if check_local_key "$key"; then
        echo "✔ $key key pair already exists"
    else
        echo "🔑 Creating $key key pair..."
        ssh-keygen -t rsa -b 4096 -f "$key" -N ""
    fi
}

# ---------------------------------------------------------------------------
# Ensures all expected keys exist; prints results
# ---------------------------------------------------------------------------
verify_existing_keys() {
    local expected=("$@")

    # Find all public keys in the directory
    mapfile -t found < <(find . -maxdepth 1 -type f -name "*.pub")

    echo "Existing public keys:"
    printf ' - %s\n' "${found[@]:-<none>}"

    if [[ ${#found[@]} -ne ${#expected[@]} ]]; then
        echo "⚠️  Expected ${#expected[@]} keys, but found ${#found[@]}"
        exit 1
    else
        echo "✔ All ${#expected[@]} keys are present"
        exit 0
    fi
}

# ---------------------------------------------------------------------------
# Main operation: ensure all keys exist
# ---------------------------------------------------------------------------
make_ssh_keys() {
    local path="$1"
    cd $path

    local keys=(
        nat-bastion
        client_key
        server_key
    )

    echo "🔍 Checking for existing SSH keys in: $path"
    verify_existing_keys "${keys[@]}"
    echo ""

    for key in "${keys[@]}"; do
        generate_key_if_missing "$key"
    done

    echo ""
    echo "✅ SSH key setup completed"
}

make_ssh_keys "$@"
