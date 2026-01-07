class BluetoothLock < Formula
  desc "Automatically disable Bluetooth when your Mac screen locks"
  homepage "https://github.com/alexcarol/bluetooth-lock"
  url "https://github.com/alexcarol/bluetooth-lock/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "MIT"

  depends_on :macos

  def install
    system "swiftc", "-O", "bluetooth-lock.swift", "-o", "bluetooth-lock"
    bin.install "bluetooth-lock"
  end

  service do
    run opt_bin/"bluetooth-lock"
    keep_alive true
    log_path var/"log/bluetooth-lock.log"
    error_log_path var/"log/bluetooth-lock.err"
  end

  def caveats
    <<~EOS
      To start bluetooth-lock now and restart at login:
        brew services start bluetooth-lock

      To stop the service:
        brew services stop bluetooth-lock
    EOS
  end

  test do
    assert_predicate bin/"bluetooth-lock", :executable?
  end
end
