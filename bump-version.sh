#!/usr/bin/env bash

set -e # Exit immediately if a command exits with a non-zero status.

TARGET_VERSION_FILE="${VERSION_FILE:-VERSION}"
DEFAULT_VERSION_FOR_NEW_CURRENT="0.1.0" # Used if 'current' is called on a non-existent file
COMMAND=$1

# --- Helper Function for Errors ---
error_exit() {
    echo "Error (bump-version.sh): $1" >&2
    exit 1
}

# --- Command Validation ---
if [[ "$COMMAND" != "current" && "$COMMAND" != "major" && "$COMMAND" != "minor" && "$COMMAND" != "patch" ]]; then
    error_exit "Invalid command: '$COMMAND'. Must be 'current', 'major', 'minor', or 'patch'."
fi

# --- 'current' command logic ---
if [ "$COMMAND" == "current" ]; then
    if [ ! -f "$TARGET_VERSION_FILE" ] || [ ! -s "$TARGET_VERSION_FILE" ]; then
        # File doesn't exist or is empty, initialize and output default
        echo "$DEFAULT_VERSION_FOR_NEW_CURRENT" > "$TARGET_VERSION_FILE"
        echo "$DEFAULT_VERSION_FOR_NEW_CURRENT"
        exit 0
    else
        # File exists, output its content
        head -n 1 "$TARGET_VERSION_FILE"
        exit 0
    fi
fi

# --- Bump commands (major, minor, patch) logic ---
M=0
m=0
p=0
version_file_existed_and_was_valid=false

if [ -f "$TARGET_VERSION_FILE" ] && [ -s "$TARGET_VERSION_FILE" ]; then
    current_full_version=$(head -n 1 "$TARGET_VERSION_FILE")
    core_version=${current_full_version%%[-+]*} # Strip pre-release/build

    if [[ "$core_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        OLD_IFS="$IFS"; IFS='.'; read -r M m p <<< "$core_version"; IFS="$OLD_IFS"
        if ! [[ "$M" =~ ^[0-9]+$ && "$m" =~ ^[0-9]+$ && "$p" =~ ^[0-9]+$ ]]; then
             # This case should ideally not be hit if the first regex passed, but for safety:
            error_exit "Failed to parse numeric components from '$core_version' in '$TARGET_VERSION_FILE'."
        fi
        version_file_existed_and_was_valid=true
    else
        # File exists but content is invalid for bumping, treat as if starting from 0.0.0
        # but log an error because existing content was bad.
        echo "Warning (bump-version.sh): '$TARGET_VERSION_FILE' contains an invalid version string ('$current_full_version'). Treating as 0.0.0 for bump." >&2
        M=0; m=0; p=0; # Reset to 0.0.0
    fi
else
    # File doesn't exist or is empty. Will proceed with M=0, m=0, p=0.
    # No output here, as per user request.
    : # Placeholder for clarity
fi

# Perform bump
case "$COMMAND" in
    "patch") p=$((p + 1)) ;;
    "minor") m=$((m + 1)); p=0 ;;
    "major") M=$((M + 1)); m=0; p=0 ;;
esac

new_version="$M.$m.$p"
echo "$new_version" > "$TARGET_VERSION_FILE"
echo "$new_version" # Output the new version to stdout

exit 0
