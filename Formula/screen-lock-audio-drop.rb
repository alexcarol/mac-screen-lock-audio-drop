class ScreenLockAudioDrop < Formula
  desc "Disconnect Bluetooth audio devices when your Mac screen locks"
  homepage "https://github.com/alexcarol/mac-screen-lock-audio-drop"
  url "https://github.com/alexcarol/mac-screen-lock-audio-drop/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "3281f4b930e30db2838eb014f8f538656b9660021c0dbe879be5e25530c3df2c"
  license "MIT"

  depends_on :macos

  def install
    system "swiftc", "-O", "screen-lock-audio-drop.swift", "-o", "screen-lock-audio-drop"
    bin.install "screen-lock-audio-drop"
  end

  service do
    run opt_bin/"screen-lock-audio-drop"
    keep_alive true
    log_path var/"log/screen-lock-audio-drop.log"
    error_log_path var/"log/screen-lock-audio-drop.err"
  end

  def post_install
    system opt_bin/"screen-lock-audio-drop", "--check-permissions"
  end

  def caveats
    <<~EOS
      Bluetooth permission is required to disconnect audio devices on screen lock.
      If you were not prompted during install, grant access manually:
        System Settings > Privacy & Security > Bluetooth

      To start screen-lock-audio-drop now and restart at login:
        brew services start screen-lock-audio-drop

      To stop the service:
        brew services stop screen-lock-audio-drop
    EOS
  end

  test do
    assert_predicate bin/"screen-lock-audio-drop", :executable?
  end
end
