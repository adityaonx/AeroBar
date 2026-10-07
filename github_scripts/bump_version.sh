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
echo "✅ Updated AeroBar.xcodeproj/project.pbxproj"

# 1b. v9.6-beta1.5x: the version compiled into the binary (decisions read this, not Info.plist)
sed -i '' -E "s/(static let version = \").*(\")/\1$NEW_VERSION\2/" AeroBar/Core/Utilities/AeroBarBuildInfo.swift
echo "✅ Updated AeroBar/Core/Utilities/AeroBarBuildInfo.swift"

# 2. Update Homebrew Cask version
sed -i '' -E "s/version \".*\"/version \"$NEW_VERSION\"/g" public/Casks/aerobar.rb
echo "✅ Updated Casks/aerobar.rb"

echo "🎉 Successfully bumped all versions to $NEW_VERSION!"
