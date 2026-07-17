cask "aerobar" do
  version "8.4-beta9"
  sha256 :no_check

  url "https://github.com/adityaonx/AeroBar/releases/download/v#{version}/AeroBar.dmg"
  name "AeroBar"
  desc "The Windows Taskbar you missed on Mac"
  homepage "https://adityaonx.github.io/AeroBar/"

  app "AeroBar.app"

  caveats <<~EOS
    AeroBar is self-signed. To avoid Gatekeeper blocks, we recommend installing with:
      brew install --cask aerobar --no-quarantine

    If you didn't use --no-quarantine and encounter a "damaged app" error, run:
      xattr -rd com.apple.quarantine /Applications/AeroBar.app
  EOS
end
