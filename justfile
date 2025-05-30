# Path to the bump script.
BUMP_SCRIPT := "./bump-version.sh"

# Default recipe if no target is given.
default: help

# Display the current version.
# If VERSION file is missing, script creates it with '0.1.0' and outputs that.
# Outputs only the version string.
current:
    @if [ ! -x "{{BUMP_SCRIPT}}" ]; then echo "Error: Script '{{BUMP_SCRIPT}}' not found or not executable." >&2; exit 1; fi
    @{{BUMP_SCRIPT}} current

# Bump the version.
# If VERSION file is missing, script effectively bumps from '0.0.0'.
# Outputs only the new version string.
# Usage: just bump major
#        just bump minor
#        just bump patch
#        just bump         (defaults to 'patch')
bump level="patch":
    @if [ ! -x "{{BUMP_SCRIPT}}" ]; then echo "Error: Script '{{BUMP_SCRIPT}}' not found or not executable." >&2; exit 1; fi
    @{{BUMP_SCRIPT}} {{level}}

# Create a git tag for the current version.
# Usage: just tag
#        just tag true  (to also push the tag to origin)
#        just tag true my-remote (to push to a specific remote)
tag push_flag="false" remote_name="origin":
    @if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then echo "Error: Not a git repository." >&2; exit 1; fi
    @if ! git diff-index --quiet HEAD --; then echo "Warning: Uncommitted changes exist. Recommended to commit before tagging." >&2; fi
    @# Get current version (script handles creation if needed)
    @current_version=$$( {{BUMP_SCRIPT}} current )
    @if [ -z "$$current_version" ]; then echo "Error: Could not retrieve current version." >&2; exit 1; fi
    @tag_name="v$$current_version"
    @echo "Attempting to create git tag: '$$tag_name'" >&2
    @if git rev-parse "$$tag_name" > /dev/null 2>&1; then echo "Error: Tag '$$tag_name' already exists." >&2; exit 1; fi
    @git tag -a "$$tag_name" -m "Release $$tag_name"
    @echo "Tag '$$tag_name' created locally." >&2
    @if [ "{{push_flag}}" = "true" ]; then \
        echo "Pushing tag '$$tag_name' to remote '{{remote_name}}'..." >&2; \
        git push {{remote_name}} "$$tag_name"; \
        echo "Tag pushed." >&2; \
    else \
        echo "To push tag: git push {{remote_name}} $$tag_name" >&2; \
    fi

# --- Help ---
help:
    @echo "Usage: just <command> [argument]"
    @echo ""
    @echo "Manages a version string in a 'VERSION' file (or file specified by VERSION_FILE env var)."
    @echo "The script '{{BUMP_SCRIPT}}' handles all logic, including file creation."
    @echo "Successful operations output only the version string to stdout."
    @echo "Errors and warnings from the script go to stderr."
    @echo ""
    @echo "Available commands:"
    @echo "  current                 Show current version. Creates 'VERSION' with '0.1.0' if missing."
    @echo "  bump <major|minor|patch> Bump the version. Defaults to 'patch'."
    @echo "                          If 'VERSION' is missing, effectively bumps from '0.0.0'."
    @echo "  tag [PUSH] [REMOTE]     Create git tag (vX.Y.Z) for current version."
    @echo "                          PUSH: 'true' to push (default: 'false'). REMOTE: (default: 'origin')."
    @echo "  help                    Show this help message."
