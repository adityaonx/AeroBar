#!/bin/bash

# Ensure a version argument is provided
if [ -z "$1" ]; then
  echo "Usage: ./bump_version.sh <new_version>"
  echo "Example: ./bump_version.sh 8.3-beta2"
  exit 1
fi

NEW_VERSION=$1

echo "Bumping version to $NEW_VERSION..."

# 1. Update Xcode project MARKETING_VERSION and CURRENT_PROJECT_VERSION
# We use sed to replace the existing versions. The '' is required for macOS sed in-place editing.
sed -i '' "s/MARKETING_VERSION = \".*\";/MARKETING_VERSION = \"$NEW_VERSION\";/g" AeroBar.xcodeproj/project.pbxproj
sed -i '' "s/CURRENT_PROJECT_VERSION = \".*\";/CURRENT_PROJECT_VERSION = \"$NEW_VERSION\";/g" AeroBar.xcodeproj/project.pbxproj
echo "Updated AeroBar.xcodeproj/project.pbxproj"

# 2. Update Homebrew Cask version
sed -i '' -E "s/version \".*\"/version \"$NEW_VERSION\"/g" Casks/aerobar.rb
echo "Updated Casks/aerobar.rb"

echo "Successfully bumped all versions to $NEW_VERSION!"
