

# Path to the bump script.
BUMP_SCRIPT := "./bump-version.sh"
VERSION := `./bump-version.sh current`



# Show help
default:
	@just --list

check-bump-script:
	@test -x {{BUMP_SCRIPT}} || { echo "Error: {{BUMP_SCRIPT}} not found or not executable" >&2; exit 1; }

# Display the current version.
current: check-bump-script
	@echo {{VERSION}}

# Bump the version.
bump level="patch": check-bump-script
	@{{BUMP_SCRIPT}} {{level}}

# Create a git tag and release for the current version.
tag: check-bump-script
	@git tag -a v{{VERSION}} -m "Version {{VERSION}}" && \
	git push origin v{{VERSION}} && \
	gh release create v{{VERSION}} --generate-notes	
