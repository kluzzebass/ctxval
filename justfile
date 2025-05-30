# Path to the bump script.
BUMP_SCRIPT := "./bump-version.sh"
VERSION := `cat VERSION`

# Default recipe if no target is given.
default: help

# Display the current version.
# Outputs only the version string.
current:
  @if [ ! -x "{{BUMP_SCRIPT}}" ]; then echo "Error: Script '{{BUMP_SCRIPT}}' not found or not executable." >&2; exit 1; fi
  @{{BUMP_SCRIPT}} current

# Bump the version.
# Outputs only the new version string.
bump level="patch":
  @if [ ! -x "{{BUMP_SCRIPT}}" ]; then echo "Error: Script '{{BUMP_SCRIPT}}' not found or not executable." >&2; exit 1; fi
  @{{BUMP_SCRIPT}} {{level}}

# Create a git tag for the current version.
# Usage: just tag
tag:
  @git tag -a v{{VERSION}} -m "Version {{VERSION}}" && \
  git push origin v{{VERSION}} && \
  gh release create v{{VERSION}} --generate-notes

# --- Help ---
help:
  @echo "Usage: just <command> [argument]"
  @echo ""
  @echo "Manages a version string using '{{BUMP_SCRIPT}}'."
  @echo "The script handles version file creation (default: 'VERSION' or via VERSION_FILE env var)."
  @echo "Successful operations output only the version string to stdout."
  @echo "Errors and most informational messages go to stderr."
  @echo ""
  @echo "Available commands:"
  @echo "  current                 Show current version. Creates 'VERSION' with '0.1.0' if missing."
  @echo "  bump <major|minor|patch> Bump the version. Defaults to 'patch'."
  @echo "  tag [PUSH] [REMOTE]     Create git tag (vX.Y.Z) for current version."
  @echo "                          PUSH: 'true' to push (default: 'false'). REMOTE: (default: 'origin')."
  @echo "  help                    Show this help message."
