cask "aerobar" do
  # v9.6-beta2.4f: the version is the real release version (private/scripts/bump_version.sh writes it) and the release asset is
  # AeroBar-<version>.dmg, the name sign-release.sh uses. Previous logic: version "latest" and url .../v#{version}/AeroBar.dmg,
  # which resolved to .../vlatest/AeroBar.dmg and could not download.
  version "9.6-beta3"
  sha256 "cc23d19a9aeef0df5ea7f03e7ac1ebbc3d7652753ec6092af92fd440f636e152"

  url "https://github.com/adityaonx/AeroBar/releases/download/v#{version}/AeroBar-#{version}.dmg"
  name "AeroBar"
  desc "The Windows Taskbar you missed on Mac"
  homepage "https://adityaonx.github.io/AeroBar/"

  # v9.6-beta2.4d: AeroBar updates through its own Update Basket (signed .dmg + .sig). With auto_updates, a plain `brew upgrade`
  # leaves AeroBar alone, so Homebrew never replaces the app behind the install guard's back. Previous logic: not set.
  auto_updates true

  app "AeroBar.app"

  caveats <<~EOS
    AeroBar updates itself through its Update Basket, not through Homebrew.
    Do not use `brew upgrade --greedy` for AeroBar: AeroBar will refuse to start a copy that did not come through the basket.
    To update, download the .dmg and .sig for the new version from the release page and drop both in the Update Basket.

    AeroBar is self-signed. To avoid Gatekeeper blocks, we recommend installing with:
      HOMEBREW_NO_QUARANTINE=1 brew install --cask aerobar

    If you didn't use HOMEBREW_NO_QUARANTINE=1 and encounter a "damaged app" error, run:
      xattr -rd com.apple.quarantine /Applications/AeroBar.app
  EOS
end
