class ScreenLockAudioDrop < Formula
  desc "Disconnect Bluetooth audio devices when your Mac screen locks"
  homepage "https://github.com/alexcarol/mac-screen-lock-audio-drop"
  url "https://github.com/alexcarol/mac-screen-lock-audio-drop/archive/refs/tags/v0.3.3.tar.gz"
  sha256 "343b60c7b3e4e4c7e41f1e70a8b5854ebb3fdc997e6f34a133d4da9b6c794b01"
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
      When the service starts, macOS asks for Bluetooth permission.
      You must allow access for the tool to work.
      If you miss the prompt: System Settings > Privacy & Security > Bluetooth,
      then restart the service.
    EOS
  end

  test do
    assert_predicate bin/"screen-lock-audio-drop", :executable?
  end
end
