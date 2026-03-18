class ScreenLockAudioDrop < Formula
  desc "Disconnect Bluetooth audio devices when your Mac screen locks"
  homepage "https://github.com/alexcarol/mac-screen-lock-audio-drop"
  url "https://github.com/alexcarol/mac-screen-lock-audio-drop/archive/refs/tags/v0.3.2.tar.gz"
  sha256 "a7896a257e0f67f93986dee52bbd8ac5895768e7048bcd733115710747acb0d0"
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
      The first time you lock your screen, macOS will ask for Bluetooth permission.
      You must unlock and allow access for the tool to work.
      If you miss the prompt: System Settings > Privacy & Security > Bluetooth
    EOS
  end

  test do
    assert_predicate bin/"screen-lock-audio-drop", :executable?
  end
end
