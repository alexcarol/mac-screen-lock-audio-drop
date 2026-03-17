class ScreenLockAudioDrop < Formula
  desc "Disconnect Bluetooth audio devices when your Mac screen locks"
  homepage "https://github.com/alexcarol/mac-screen-lock-audio-drop"
  url "https://github.com/alexcarol/mac-screen-lock-audio-drop/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
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

      To stop the service:
        brew services stop screen-lock-audio-drop
    EOS
  end

  test do
    assert_predicate bin/"screen-lock-audio-drop", :executable?
  end
end
