# Path to the bump script.
BUMP_SCRIPT := "./bump-version.sh"
VERSION := `cat VERSION`

# Show help
default:
  @just --list

# Display the current version.
current:
  @if [ ! -x "{{BUMP_SCRIPT}}" ]; then echo "Error: Script '{{BUMP_SCRIPT}}' not found or not executable." >&2; exit 1; fi
  @{{BUMP_SCRIPT}} current

# Bump the version.
bump level="patch":
  @if [ ! -x "{{BUMP_SCRIPT}}" ]; then echo "Error: Script '{{BUMP_SCRIPT}}' not found or not executable." >&2; exit 1; fi
  @{{BUMP_SCRIPT}} {{level}}

# Create a git tag and release for the current version.
tag:
  @git tag -a v{{VERSION}} -m "Version {{VERSION}}" && \
  git push origin v{{VERSION}} && \
  gh release create v{{VERSION}} --generate-notes

