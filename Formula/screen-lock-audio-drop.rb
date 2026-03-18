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

  def caveats
    <<~EOS
      To start screen-lock-audio-drop now and restart at login:
        brew services start screen-lock-audio-drop

      The first time you lock your screen, macOS will ask for Bluetooth permission.
      You must unlock and allow access for the tool to work.
      If you miss the prompt: System Settings > Privacy & Security > Bluetooth

      To stop the service:
        brew services stop screen-lock-audio-drop
    EOS
  end

  test do
    assert_predicate bin/"screen-lock-audio-drop", :executable?
  end
end
